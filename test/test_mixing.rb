require 'test/unit'

def add_update_proc( * ) end
def add_conf_proc( * ) end
def add_edit_proc( * ) end
require File.expand_path(File.dirname(__FILE__) + '/../plugin/ja/mixing.rb')
require File.expand_path(File.dirname(__FILE__) + '/../plugin/mixing.rb')

class MixingTest < Test::Unit::TestCase
  def setup
    conf = {}
    conf['mixing.userid'] = ENV['MIXING_ID']
    conf['mixing.password'] = ENV['MIXING_PW']
    @mixing = Mixing::new( conf )
  end

  def test_login
    assert_not_nil @mixing.login
  end

  def test_diary_update
    ctx = []
    ctx << {
      'body' => 'スクリプトテスト',
      'subtitle' => 'test'
    }
    assert_not_nil @mixing.login
    assert_not_nil(@mixing.add_diary(ctx))
  end
end
