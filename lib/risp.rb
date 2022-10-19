require 'singleton'

module Risp
  class Reader
    def initialize(state, src)
      @state = state
      @src = src
      @fib = Fiber.new(&method(:scan_loop))
      @buf = []
    end

    def read
      #1parse_atom @src.each_line.next.slice(/\S+/).downcase
      t = next_token()
      case t.tag
      when :EOF
        nil
      when '('
        read_list t
      when :STRING_BEGIN
        read_string t
      when :ATOM
        parse_atom t
      else
        unexpected t
      end
    end

    private

    def unexpected(t)
      s = (t.tag == t.value ? t.tag.inspect : "#{t.value.inspect}(#{t.tag})")
      raise "#{t.lineno}:#{t.column}: unexpected token - #{s}"
    end

    def read_list(beg)
    end

    def read_string(beg)
    end

    def parse_atom(t)
      s = t.value.downcase
      case
      when s == 't'
        T.instance
      when s == 'nil' 
        Nil.instance
      when n = Kernel.Integer(s, exception: false)
        Integer.new(n)
      when x = Kernel.Float(s, exception: false)
        Float.new(x)
      else
        parse_symbol t
      end
    end

    def parse_symbol(t)
      case src = t.value.downcase
      when /\A:/
        Symbol.new(src.delete_prefix(':').intern, @state.keyword_package)
      when /\A([^:]+?)::/
        Symbol.new($'.intern, @state.define_package($1.intern))
      when /\A([^:]+?):/
        Symbol.new($'.intern, @state.define_package($1.intern))
      else
        Symbol.new(src.intern, @state.current_package)
      end
    end

    def next_token
      @buf.empty? ? @fib.resume : @buf.pop
    end

    def pushback(token)
      @buf.push token if token
      nil
    end

    Token = Struct.new(:tag, :value, :lineno, :column)

    def emit(tag = @s.matched, val = @s.matched)
      Fiber.yield Token.new(tag, val, @lineno, @last_pos + 1)
    end

    def scan(re)
      @last_pos = @s.pos
      @s.scan(re)
    end

    def scan_loop
      @lineno = 1
      @s = StringScanner.new('')
      meth = :scan_default
      @src.each_line do |line|
        @s.string = line
        meth = send(meth) until @s.eos?
        @lineno += 1
      end
      emit :EOF, nil
    end

    def scan_default
      case
      when scan(/\s+/), scan(/;.*/)
        ;
      when scan(/,@/), scan(/[().'`,]/)
        emit
      when scan(/"/)
        emit :STRING_BEGIN
        return :scan_string
      when scan(/[^\s;"()'`,]+/)
        emit :ATOM
      else
        raise Exception, 'must not happen'
      end
      __method__
    end

    ESC = {
      'n' => "\n",
      't' => "\t",
    }

    def scan_string
      case
      when scan(/\\(.)/)
        emit :STRING_CONTENT, ESC[@s[1]] || s[1]
      when scan(/"/)
        emit :STRING_END
        return :scan_default
      when scan(/[^"\\]+/)
        emit :STRING_CONTENT
      else
        raise Exception, 'must not happen'
      end
      __method__
    end
  end

  class T
    include Singleton
  end

  class Nil
    include Singleton
  end

  class Integer
    def initialize(n)
      @value = n
    end

    attr_reader :value

    def ==(other)
      self.class == other.class and self.value == other.value
    end
  end

  class Float
    def initialize(x)
      @value = x
    end

    attr_reader :value

    def ==(other)
      self.class == other.class and self.value == other.value
    end
  end

  class Symbol
    def initialize(name, package)
      @name = name
      @package = package
    end

    attr_reader :name, :package

    def ==(other)
      self.class == other.class and
        self.name == other.name and
        self.package == other.package
    end
  end

  class Package
    def initialize(name)
      @name = name
    end
  end

  class State
    def initialize
      @packages = {}
      @current_package = define_package(:"risp-user")
      @keyword_package = define_package(:keyword)
    end

    attr_reader :current_package, :keyword_package

    def define_package(name)
      @packages[name] ||= Package.new(name)
    end

    def find_package(name)
      @packages[name]
    end
  end
end

