#!/usr/bin/env ruby

# Purpose : A simple proxy to handle Github hook before sending to Jenkins
# Author  : Ky-Anh Huynh
# Date    : 2018 July 08
# License : MIT

# Custom information
AVAILABLE_TYPES = %{push create delete pull_request}
JENKINS_HOST = "localhost"
JENKINS_PORT = "8080"
PAYLOADS_DIR = (ENV["D_PAYLOADS"] || "./payloads/")

require 'sinatra'
require 'net/http'
require 'json'
require 'uri'
require 'digest'

set :show_exceptions, false
set :raise_errors, false
set :port, (ENV['PORT'] || 8081)

# See https://stackoverflow.com/questions/31443058/how-to-set-the-default-error-pages-for-a-basic-webrick-server
module WEBrick
  class HTTPResponse
    def create_error_page
      @body = ''
      @body << <<-EOF
Ops, are you hacking us?
      EOF
    end
  end
end

def process_payload(payload, hook_type)
  if not AVAILABLE_TYPES.include?(hook_type)
    return {by_pass: false, reason: "Unsupport hook type: '#{hook_type}'"}
  end

  if hook_type != "push"
    return {by_pass: true, reason: "Hook type is not push."}
  end

  ret = {by_pass: true, reason: "Unknown reason"}

  begin
    payload = JSON.parse(payload.to_s)
  rescue => e
    logger.error "process_payload: Incoming payload parsing error: #{e}"
    "Ops, are you hacking us?\n"
    return {by_pass: false, reason: "Error parsing payload string."}
  end

  git_ref = payload["ref"]
  git_head_commit = payload["head_commit"]
  git_url = (git_head_commit ? git_head_commit["url"] : "")

  if git_head_commit and git_ref
    if git_head_commit["message"].match(%r{\[(skip ci)|(ci skip)\]}i)
      ret[:reason] = "Last commit has [skip ci] or [ci skip]. URL: #{git_url}"
      ret[:by_pass] = false
    elsif git_head_commit["message"].match(%r{^doc: }i)
      ret[:by_pass] = false
      ret[:reason] = "Last commit is related to documentation. URL: #{git_url}"
    elsif git_ref.match(%r{/v?\d+\.\d+\.\d+})
      ret[:by_pass] = false
      ret[:reason] = "Ref '#{git_ref}' is a tag. URL: #{git_url}"
    end
  end

  ret
end

def bypass_payload(upstream_request, payload, hook_type = "push")
  t_start = Time.now
  begin
    j_http = Net::HTTP.new(JENKINS_HOST, JENKINS_PORT)
    j_headers = {
      'X-GitHub-Event' => hook_type,
      'X-Hub-Signature'=> upstream_request.env['X-Hub-Signature'],
      'X-GitHub-Delivery' => upstream_request.env['X-GitHub-Delivery'],
      'User-Agent' => upstream_request.env['User-Agent'],
      'Content-Type' => 'application/x-www-form-urlencoded'
    }

    j_request = Net::HTTP::Post.new(upstream_request.env['PATH_INFO'])
    j_headers.each do |k,v|
      j_request[k] = v
    end
    j_request.body = "payload=#{payload}"
    j_response = j_http.request(j_request)

    t_end = Time.now
    logger.warn "bypass_payload: Jenkins response: #{j_response.inspect}"

    "Payload sent to Jenkins. Elapsed time #{t_end - t_start}. Thanks.\n"
  rescue => ee
    logger.warn "bypass_payload: Payload sent to Jenkins with error: #{ee}."
    "Payload sent to Jenkins (with error).\n"
  end
end

def save_payload(prefix, request, params)
  begin
    if params["payload"]
      File.open("#{PAYLOADS_DIR}/#{prefix}.#{Digest::SHA256.hexdigest(params["payload"])}.payload", "w") do |f|
        %w{HTTP_USER_AGENT HTTP_X_GITHUB_EVENT HTTP_X_GITHUB_DELIVERY}.each do |jenv|
          f.puts "Header: #{jenv} #{request.env[jenv]}"
        end
        f.puts "\nPayload:\n#{params["payload"]}"
      end
    end
  rescue => e
    logger.error "save_payload: Something wrong: #{e}"
  end
end

get '/*' do
  "Hello, world.\n"
end

post '/github-webhook/?' do
  hook_type = request.env["HTTP_X_GITHUB_EVENT"]
  save_payload(:github, request, params)
  ret = process_payload(params["payload"], hook_type)
  if ret[:hotfix]
    schedule_remote_job(request, ret[:repo_name])
  elsif ret[:by_pass]
    bypass_payload(request, params["payload"], hook_type)
  else
    logger.warn "Payload discarded. Reason: #{ret[:reason]}."
    "Payload discarded.\n"
  end
end

post '/*' do
  "Hello, world.\n"
end

error do
  "Ops, are you hacking us?\n"
end
