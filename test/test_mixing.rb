# -*- coding: utf-8 -*-
require 'test/unit'
#require 'hpricot'
require 'logger'

def add_update_proc( * ) end
def add_conf_proc( * ) end
def add_edit_proc( * ) end
require File.expand_path(File.dirname(__FILE__) + '/../plugin/ja/mixing.rb')
require File.expand_path(File.dirname(__FILE__) + '/../plugin/mixing.rb')

class MixingTest < Test::Unit::TestCase
  class Config < Hash
    def initialize
      super
    end
    def section_anchor
      '<span>■</span>'
    end
  end

  def setup
    @conf = Config.new
    @mixing = Mixing::Agent.new(@conf)
    @mail = ENV['MIXING_ID']
    @password = ENV['MIXING_PW']
    WWW::Mechanize.log = Logger.new('test.log')
    WWW::Mechanize.log.level = Logger::INFO
#    WWW::Mechanize.html_parser = Hpricot
  end

  def test_login
    assert_not_nil @mixing.login(@mail, @password)
  end

  def test_add_last_section
    ctx = {}
    ctx[:sections] = []
    ctx[:images] = []
    ctx[:sections] << {
      :subtitle => 'test',
      :body => '<p>スクリプトテスト</p>'
    }
    assert_not_nil @mixing.login(@mail, @password)
    assert_not_nil(@mixing.add_last_section(ctx))
  end

  def test_multi_section_diary
    ctx = {}
    ctx[:title] = 'マルチセクションテスト'
    ctx[:images] = []
    ctx[:sections] = [
      { :subtitle => 'マルチセクション１',
        :body => "<p>パラグラフ１</p><p>パラグラフ２</p>"},
      { :subtitle => 'マルチセクション２',
        :body => '<p>ほげほげ</p>'}]

    @mixing.login(@mail, @password)
    assert_not_nil(@mixing.add_diary(ctx))
  end
  
  def test_diary_rule
    ctx = {}
    ctx[:title] = 'ダイアリールール'
    ctx[:images] = []
    ctx[:sections] = [
      { :subtitle => 'ダイアリー１',
        :body => "<p>パラグラフ１</p><p>パラグラフ２</p>"},
      { :subtitle => 'ダイアリー２',
        :body => '<p>ほげほげ</p>'}]

    rule = Mixing::DiaryRule.new(@conf)
    rule.login(@mail, @password)
    rule.append(ctx)
  end

  def test_section_rule
    ctx = {}
    ctx[:title] = 'セクションルール'
    ctx[:images] = []
    ctx[:sections] = [
      { :subtitle => 'セクション１',
        :body => "<p>パラグラフ１</p><p>パラグラフ２</p>"},
      { :subtitle => 'セクション２',
        :body => '<p>ほげほげ</p>'}]

    rule = Mixing::SectionRule.new(@conf)
    rule.login(@mail, @password)
    rule.append(ctx)
  end

  def test_update_diary
    ctx = {}
    ctx[:title] = '日記更新テスト'
    ctx[:images] = []
    ctx[:sections] = []
    ctx[:sections] << {
      :subtitle => '日記更新テスト',
      :body => '<p>スクリプトテスト</p>'
    }
    assert_not_nil(@mixing.login(@mail, @password))
    assert_not_nil(@mixing.add_last_section(ctx))

    ctx[:sections][0][:body] = '<p>スクリプトで更新</p>'
    @mixing.update_diary(ctx)
  end

  def test_update_section
    ctx = {}
    ctx[:title] = 'セクション更新テスト'
    ctx[:images] = []
    ctx[:sections] = [
      { :subtitle => 'セクション更新１',
        :body => "<p>パラグラフ１</p><p>パラグラフ２</p>"}]
    assert_not_nil(@mixing.login(@mail, @password))
    assert_not_nil(@mixing.add_last_section(ctx))

    ctx[:sections] << { 
        :subtitle => 'セクション更新２',
        :body => '<p>ほげほげ</p>'}

    assert_not_nil(@mixing.add_last_section(ctx))

    ctx[:sections][0][:body] = '<p>スクリプトでセクション再更新１</p>'
    ctx[:sections][1][:body] = '<p>スクリプトでセクション再更新２</p>'
    @mixing.update_section(ctx)
  end

  def test_fileupload
    ctx = {}
    ctx[:title] = '画像アップロードテスト'
    ctx[:sections] = [
      { :subtitle => 'マルチセクション１',
        :body => "<p>パラグラフ１</p><p>パラグラフ２</p>"}]
    ctx[:images] = [
      File.dirname(__FILE__) + '/sakura.jpg'
    ]

    rule = Mixing::DiaryRule.new(@conf)
    rule.login(@mail, @password)
    rule.append(ctx)
  end
end
