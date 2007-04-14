# mixing.rb
#
# mixi.jp updateing.
#
# options configurable through settings:
#   @conf['mixing.userid'] : mixi login userid(e-mail)
#   @conf['mixing.password'] : mixi login passord
#
# Copyright (c) 2007 Koichiro Ohba <koichiro@meadowy.org>
# Distributed under the GPL
#

class Mixing
  MIXI_URL = 'http://mixi.jp'

  def initialize( conf )
    @conf = conf
    require 'rubygems'
    require 'mechanize'
    @agent = WWW::Mechanize.new
    @agent.user_agent_alias = 'Mac Safari'
  end

  def login
    page = @agent.get(MIXI_URL + '/')
    form = page.forms.action('login.pl').first
    form.email = @conf['mixing.userid']
    form.password = @conf['mixing.password']
    @agent.submit(form)
    @agent.get(MIXI_URL + '/check.pl?n=%2Fhome.pl')
  end

  def add_diary(ctx)
    section = ctx.last
    edit_diary(html_strip(section['subtitle']), html_strip(section['body']))
  end

  def edit_diary(title = '', content  = '')
    begin
      open_edit_diary
      input_diary(title, content)
      confirm_diary
    rescue
      p $!.to_s
      p $!.backtrace
    end
  end

  private

  def open_edit_diary
    page = @agent.get(MIXI_URL + '/list_diary.pl')
    form = page.forms.action('add_diary.pl').first
    r = @agent.submit(form)
  end

  def input_diary(title, content)
    page = @agent.page
    form = page.forms.with.name('diary').first
    form.diary_title = title
    form['diary_body'] = content
    r = @agent.submit(form)
  end

  def confirm_diary
    page = @agent.page
    form = page.forms.action('add_diary.pl').first
    r = @agent.submit(form)
#    p r.body
  end

  def html_strip( s )
    s.gsub(/<.*?>/, "")
  end
end

@mixing = Mixing::new( @conf )

def mixing_update
  return if /^comment|^showcomment/ =~ @mode

  log = File.open('/tmp/debug.log', 'a+w')

  log.puts(@mode)

  date = @date.strftime( "%Y%m%d" )
  diary = @diaries[date]
  return unless diary || diary.visible?

  mixi_context = []

  diary.each_section do |section|
    mixi_context << {
      'body' => section.body_to_html,
      'subtitle' => section.subtitle_to_html
    }
  end

  log.puts(mixi_context.to_s)

  if @mode == 'append' then
    @mixing.add_diary( mixi_context )
  elsif @mode == 'replace' then
  end

  log.close
end

def mixing_update_proc
  return unless @conf['mixing.userid'] || @conf['mixing.password']
  return if @cgi.params['mixing_update'][0] == 'false'

  mixing_update
end

add_update_proc do
  mixing_update_proc
end

def mixing_conf_html
  <<-HTML
  <h3 class="subtitle">#{@mixing_label}</h3>
  <p>#{@mixing_desc}</p>
  <h3 class="subtitle">#{@mixing_userid_label}</h3>
  <p>#{@mixing_userid_desc}</p>
  <p><input type="text" name="mixing.userid" value="#{CGI::escapeHTML( @conf['mixing.userid'] ) if @conf['mixing.userid']}"></p>
  <h3 class="subtitle">#{@mixing_password_label}</h3>
  <p>#{@mixing_password_desc}</p>
  <p><input type="password" name="mixing.password" value="#{CGI::escapeHTML( @conf['mixing.password'].unpack('m').first ) if @conf['mixing.password']}"></p>
  <h3 class="subtitle">#{@mixing_default_update_label}</h3>
  <p><input type="checkbox" name="mixing.default_update" value="true"#{@conf['mixing.default_update'] ? ' checked': ''}>#{@mixing_default_update_desc}</input></p>
  HTML
end

add_conf_proc( 'mixing', @mixing_label, 'update' ) do
  if @mode == 'saveconf' then
		%w( userid password default_update ).each do |s|
			item = "mixing.#{s}"
			@conf[item] = @cgi.params[item][0]
		end
    @conf['mixing.default_update'] = @conf['mixing.default_update'] == 'true' ? true : false
    @conf['mixing.password'] = [@conf['mixing.password']].pack('m') if @conf['mixing.password']
  end

  mixing_conf_html
end

def mixing_edit_proc
  return unless @conf['mixing.userid'] || @conf['mixing.password']
  return if @conf['mixing.userid'] == '' || @conf['mixing.password'] == ''

  checked = @conf['mixing.default_update'] ? ' checked' : ''
  checked = @cgi.params['mixing_update'][0] == 'true' ? ' checked' : '' if @cgi.params['mixing_update'][0]
  r = <<-HTML
  <input type="checkbox" name="mixing_update" value="false"#{checked} />
  #{@mixing_edit_label}
  HTML
end

add_edit_proc do
  mixing_edit_proc
end
