require 'risp'
require 'stringio'

RSpec.describe Risp::Reader do
  context '#read' do
    context 'シンボル' do
      it '普通のシンボルの読み込み' do
        state = Risp::State.new
        reader = Risp::Reader.new(state, 'hoge')
        expect(reader.read).to eq(Risp::Symbol.new(:hoge, state.current_package))
      end

      it 'IOからの読み込み' do
        state = Risp::State.new
        reader = Risp::Reader.new(state, StringIO.new('hoge'))
        expect(reader.read).to eq(Risp::Symbol.new(:hoge, state.current_package))
      end

      it 'シンボルの印字名の英字は小文字に正規化される' do
        state = Risp::State.new
        reader = Risp::Reader.new(state, 'HoGe')
        expect(reader.read).to eq(Risp::Symbol.new(:hoge, state.current_package))
      end

      it 'コロンから始まる印字名はキーワード' do
        state = Risp::State.new
        reader = Risp::Reader.new(state, ':hoge')
        expect(reader.read).to eq(Risp::Symbol.new(:hoge, state.keyword_package))
      end

      it '外部シンボルへのアクセス' do
        state = Risp::State.new
        reader = Risp::Reader.new(state, 'hoge:piyo')
        expect(reader.read).to eq(Risp::Symbol.new(:piyo, state.define_package(:hoge)))
      end
      
      it '内部シンボルへのアクセス' do
        state = Risp::State.new
        reader = Risp::Reader.new(state, 'hoge::piyo')
        expect(reader.read).to eq(Risp::Symbol.new(:piyo, state.define_package(:hoge)))
      end
    end

    it 't' do
      state = Risp::State.new
      reader = Risp::Reader.new(state, 't')
      expect(reader.read).to eq(Risp::T.instance)
    end

    it 'nil' do
      state = Risp::State.new
      reader = Risp::Reader.new(state, 'nil')
      expect(reader.read).to eq(Risp::Nil.instance)
    end

    context '数値リテラル' do
      it '普通の整数' do
        state = Risp::State.new
        reader = Risp::Reader.new(state, '123')
        expect(reader.read).to eq(Risp::Integer.new(123))
      end

      it '普通の少数' do
        state = Risp::State.new
        reader = Risp::Reader.new(state, '12.3')
        expect(reader.read).to eq(Risp::Float.new(12.3))
      end
    end

    context 'リスト' do
      it '空リスト -> nil' do
        state = Risp::State.new
        reader = Risp::Reader.new(state, '()')
        expect(reader.read).to eq(Risp::Nil.instance)
      end
    end
  end
end

