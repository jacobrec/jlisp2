def cons(a, b)
  List.new a, b
end

def map(fn, list)
  list.nil? ? nil : cons(fn.call(list.car), map(fn, list.cdr))
end

def length(list)
  list.nil? ? 0 : (length(list.cdr) + 1)
end

class List
  @car = nil
  @cdr = nil
  attr_accessor :car, :cdr

  def self.from_array(a)
    if a.length == 0
      return nil
    else
      List.new(a.first, List.from_array(a[1..]))
    end
  end

  def to_array()
    return [nil] if self.car == nil && self.cdr == nil
    return [self.car] if self.cdr == nil
    [self.car].concat(self.cdr.to_array)
  end

  def initialize(a, b)
    @car = a
    @cdr = b
  end

  def to_s
    "(#{self.to_s_no_outer})"
  end

  def to_s_no_outer
    if @cdr.nil?
      "#{@car}"
    elsif @cdr.class == List
      "#{@car} #{@cdr.to_s_no_outer}"
    else
      "#{@car} . #{@cdr}"
    end
  end

  def [](i)
    raise "Index out of bounds (negative)" if i < 0
    if i == 0
      self.car
    elsif length(self) > i
      self.cdr[i-1]
    else
      nil
    end
  end

  def ==(other)
     other.class == List && other.car == self.car && other.cdr == self.cdr
  end
end

class Array
  def to_list
    List.from_array self
  end
end
