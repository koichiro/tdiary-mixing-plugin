# -*- coding: utf-8 -*-
# mixing.rb
#
# mixi.jp updating.
#
# options configurable through settings:
#   @conf['mixing.userid'] : mixi login userid(e-mail)
#   @conf['mixing.password'] : mixi login password
#
# Copyright (c) 2007-2009 Koichiro Ohba <koichiro@meadowy.org>
# Distributed under the GPL
#
require 'rubygems'
require 'mechanize'
require 'kconv'

module Mixing

class Agent
  MIXI_URL = 'http://mixi.jp'

  def initialize(conf)
    @conf = conf
    @agent = WWW::Mechanize.new
    @agent.user_agent_alias = 'Mac Safari'
#    @agent.user_agent_alias = 'Windows IE 6'
#    @agent.user_agent_alias = 'Mechanize'
#    @agent.user_agent_alias = 'Linux Mozilla'
  end

  def login(userid, password)
    page = @agent.get(MIXI_URL + '/')
    page.form_with(:name => 'login_form') do |f|
      f.field_with(:name => 'email').value = userid
      f.field_with(:name => 'password').value = password
      f.click_button
    end
  end

  def add_last_section(ctx)
    section = ctx[:sections].last
    edit_diary(html_strip(section[:subtitle]), html_strip(section[:body]), ctx[:images])
  end

  def add_new_section(ctx)
    ctx[:sections].each do |section|
      title = html_strip(section[:subtitle])
      # not same diary
      link = find_diary(title)
      edit_diary(title, html_strip(section[:body]), ctx[:images]) unless link
    end
  end

  def add_diary(ctx)
    content = serial_diary(ctx)
    edit_diary(ctx[:title], content, ctx[:images])
  end

  def edit_diary(title = '', content  = '', images = [])
    begin
      open_edit_diary
      input_diary(title, content, images)
      confirm_add_diary
    rescue
      p $!.to_s
      p $!.backtrace
    end
  end

  def update_section(ctx)
    ctx[:sections].each do |section|
      title = html_strip(section[:subtitle])
      body = html_strip(section[:body])
      find_update_diary(title, body, ctx[:images])
    end
  end

  def update_diary(ctx)
    begin
      title = ctx[:title]
      content = serial_diary(ctx)
      find_update_diary(title, content, ctx[:images])
    rescue
      p $!.to_s
      p $!.backtrace
    end
  end

  def find_update_diary(title, content, images)
    link = find_diary(title)
    unless link
      # added new diary
      edit_diary(title, content, images)
      return
    end
    link.href =~ /id=([0-9]+)&owner_id=([0-9]+)/
    id = $1
    owner_id = $2
    open_edit_diary_at(id)
    input_diary(title, content)
    confirm_edit_diary
  end

  def code_conv(s)
    return s.toeuc unless WWW::Mechanize.html_parser == Nokogiri::HTML
    s
  end

  def find_diary(title)
    page = @agent.page
    page = (page.uri == MIXI_URL + '/list_diary.pl') ? page : @agent.get(MIXI_URL + '/list_diary.pl')
    page.links_with(:href => /view_diary\.pl.*/).each do |link|
#      if link.text == title
#        p "Hit!"
#        p link.href
#        p "#{title} = #{link.text}"
#      end
      return link if link.text == code_conv(title)
    end
    return nil
  end

  private

  def serial_diary(ctx)
    content = ''
    ctx[:sections].each do |section|
      content += "\n" if content != ''
      content += html_strip(@conf.section_anchor) + ' ' + html_strip(section[:subtitle]) + "\n"
      content += html_strip(section[:body])
    end
    content
  end

  def open_edit_diary
    page = @agent.page.uri == MIXI_URL + '/home.pl' ? @agent.page : @agent.get(MIXI_URL + '/home.pl')
    link = page.link_with(:href => /add_diary\.pl/)
    link.click
  end

  def open_edit_diary_at(id)
    page = @agent.page
    page = (page.uri == MIXI_URL + '/list_diary.pl') ? page : @agent.get(MIXI_URL + '/list_diary.pl')
    link = page.link_with(:href => /edit_diary.pl\?id=#{id}/)
    link.click
  end

  def input_diary(title, content, images = [])
    form = @agent.page.form_with(:name => 'diary')
    form.field_with(:name => 'diary_title').value = code_conv(title)
    form.field_with(:name => 'diary_body').value = code_conv(content)

    # image upload
    i = 1
    images.each do |image|
      break if i > 3
      form.file_upload_with("photo" + i.to_s).file_name = image.untaint
      i += 1
    end

    r = form.click_button
  end

  def confirm_add_diary
   confirm_diary('add_diary.pl')
  end
  
  def confirm_edit_diary
    confirm_diary('edit_diary.pl')
  end

  def confirm_diary(action)
    page = @agent.page
    r = nil
    page.form_with(:action => action) do |f|
      r = f.click_button
    end
    r
  end

  def html_strip( s )
    return '' unless s
    s.gsub("</p>", "\n").gsub(/<.*?>/, "")
  end
end

class Rule
  def initialize(conf)
    @mixing = Agent.new(conf)
  end
  
  def login(userid, password)
    @mixing.login(userid, password)
  end
  
  def append( ctx ) end
  def replace( ctx ) end
end

class SectionRule < Rule
  def append( ctx )
    @mixing.add_new_section( ctx )
  end

  def replace( ctx )
    @mixing.update_section( ctx )
  end
end

class DiaryRule < Rule
  def append( ctx )
    @mixing.add_diary( ctx )
  end
  
  def replace( ctx )
    @mixing.update_diary( ctx )
  end
end

end

def mixing_pick_image( date )
  return [] unless respond_to?(:image_list)
  return [] unless @image_dir
  images = image_list( date )
  r = []
  images.each do |image|
    next unless /\.jpg|\.jpeg/ =~ File.extname(image)
    r << @image_dir + '/' + image
  end
  r
end

def mixing_update
  return if /^comment|^showcomment/ =~ @mode

  date = @date.strftime( "%Y%m%d" )
  diary = @diaries[date]

  return unless diary || diary.visible?

#  log = File.open('E:\users\koichiro\workspace\mixing\debug.log', 'a+')
#  log.puts('--------------------------------')
#  log.puts(@mode)
#  log.puts(diary.to_s)
#  log.close

  mixi_context = {}
  mixi_context[:title] = diary.title == '' ? code_conv('タイトル') : diary.title
  mixi_context[:sections] = []

  diary.each_section do |section|
    mixi_context[:sections] << {
      :body => apply_plugin( section.body_to_html ),
      :subtitle => section.stripped_subtitle ? section.stripped_subtitle_to_html : mixi_context[:title]
    }
  end

  mixi_context[:images] = mixing_pick_image( date )

  rule = @conf['mixing.section_to_diary'] == false ? Mixing::DiaryRule.new(@conf) : Mixing::SectionRule.new(@conf)
  rule.login(@conf['mixing.userid'], @conf['mixing.password'].unpack('m').first)
  # append / replace
  rule.send(@mode, mixi_context)
end

def mixing_update_proc
  return unless @conf['mixing.userid'] || @conf['mixing.password']
  return unless @cgi.params['mixing_update'][0] == 'true'

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
  <h3 class="subtitle">#{@mixing_section_to_diary_label}</h3>
  <p><input type="radio" name="mixing.section_to_diary" value="section_to_diary"#{(@conf['mixing.section_to_diary'] == nil || @conf['mixing.section_to_diary']) ? ' checked' : ''}>#{@mixing_section_to_diary_desc}</input></p>
  <p><input type="radio" name="mixing.section_to_diary" value="diary_to_diary"#{@conf['mixing.section_to_diary'] == false ? ' checked' : ''}>#{@mixing_diary_to_diary_desc}</input></p>
  HTML
end

add_conf_proc( 'mixing', @mixing_label, 'update' ) do
  if @mode == 'saveconf' then
		%w( userid password default_update section_to_diary ).each do |s|
			item = "mixing.#{s}"
			@conf[item] = @cgi.params[item][0]
		end
    @conf['mixing.default_update'] = @conf['mixing.default_update'] == 'true' ? true : false
    @conf['mixing.password'] = [@conf['mixing.password']].pack('m') if @conf['mixing.password']
    @conf['mixing.section_to_diary'] = @conf['mixing.section_to_diary'] == 'section_to_diary' ? true : false
  end

  mixing_conf_html
end

def mixing_edit_proc
  return unless @conf['mixing.userid'] || @conf['mixing.password']
  return if @conf['mixing.userid'] == '' || @conf['mixing.password'] == ''

  checked = @conf['mixing.default_update'] ? ' checked' : ''
  checked = @cgi.params['mixing_update'][0] == 'true' ? ' checked' : '' if @cgi.params['mixing_update'][0]
  r = <<-HTML
  <div class="checkbox">
  <input type="checkbox" name="mixing_update" value="true"#{checked} >
  </div>
  #{@mixing_edit_label}
  HTML
end

add_edit_proc do
  mixing_edit_proc
end
