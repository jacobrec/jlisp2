class Context
  def initialize(prev=nil)
    @prev = prev
    @data = {}
  end

  def get(key)
    if @data.key? key
      @data[key]
    else
      (!@prev.nil? && @prev.get(key)) || nil
    end
  end

  def put(key, val)
    @data[key] = val
  end

  def set(key, val)
    if @data.key? key
      @data[key] = val
    else
      if !@prev.nil?
        @prev.set(key, val)
      else
        raise "Cannot set value that does not exist"
      end
    end
  end

  def prev
    @prev
  end
end

class Enviroment
  def initialize(items={})
    @ctx = Context.new
    add_all(items)
  end

  def push(items={})
    ctx = Context.new(@ctx)
    @ctx = ctx
    add_all(items)
  end

  def pop()
    if @ctx.prev.nil?
      raise "no enviroment to pop"
    else
      @ctx = @ctx.prev
    end
  end

  def get(key)
    @ctx.get(key)
  end
  def put(key, val)
    @ctx.put(key, val)
  end
  def set(key, val)
    @ctx.set(key, val)
  end

  def clone
    e = Enviroment.new
    e.ctx = @ctx
    e
  end

  def ctx=(val)
    @ctx = val
  end

  def ctx
    @ctx
  end

  def become(other)
    @ctx = other.ctx
  end

  private
  def add_all(items)
    for x in items do
      @ctx.put(x[0], x[1])
    end
  end
end
