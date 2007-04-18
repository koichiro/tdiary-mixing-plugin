require 'test/unit'

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
    @mixing = Mixing::Mixing.new(@conf)
    @mail = ENV['MIXING_ID']
    @password = ENV['MIXING_PW']
  end

  def test_login
    assert_not_nil @mixing.login(@mail, @password)
  end

  def test_add_last_section
    ctx = {}
    ctx['sections'] = []
    ctx['sections'] << {
      'subtitle' => 'test',
      'body' => '<p>スクリプトテスト</p>'
    }
    assert_not_nil @mixing.login(@mail, @password)
    assert_not_nil(@mixing.add_last_section(ctx))
  end

  def test_multi_section_diary
    ctx = {}
    ctx['title'] = '大タイトル'
    ctx['sections'] = [
      { 'subtitle' => 'マルチセクション１',
        'body' => "<p>パラグラフ１</p><p>パラグラフ２</p>"},
      { 'subtitle' => 'マルチセクション２',
        'body' => '<p>ほげほげ</p>'}]

    @mixing.login(@mail, @password)
    assert_not_nil(@mixing.add_diary(ctx))
  end
  
  def test_diary_rule
    ctx = {}
    ctx['title'] = '大タイトル'
    ctx['sections'] = [
      { 'subtitle' => 'マルチセクション１',
        'body' => "<p>パラグラフ１</p><p>パラグラフ２</p>"},
      { 'subtitle' => 'マルチセクション２',
        'body' => '<p>ほげほげ</p>'}]

    rule = Mixing::DiaryRule.new(@conf)
    rule.login(@mail, @password)
    rule.append(ctx)
  end

  def test_section_rule
    ctx = {}
    ctx['title'] = '大タイトル'
    ctx['sections'] = [
      { 'subtitle' => 'マルチセクション１',
        'body' => "<p>パラグラフ１</p><p>パラグラフ２</p>"},
      { 'subtitle' => 'マルチセクション２',
        'body' => '<p>ほげほげ</p>'}]

    rule = Mixing::Section.new(@conf)
    rule.login(@mail, @password)
    rule.append(ctx)
  end
end
