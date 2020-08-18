def cons(a, b)
  List.new a, b
end

def map(fn, list)
  if list.nil?
    nil
  else
    cons fn.call(list.car), map(fn, list.cdr)
  end
  
end

def length(list)
  if list.nil?
    0
  else
    length(list.cdr) + 1
  end
  
end

class List
  @car = nil
  @cdr = nil

  def self.from_array(a)
    if a.length == 0
      return nil
    else
      List.new(a.first, List.from_array(a[1..]))
    end
  end

  def to_array()
    return [] if self.car == nil
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

  def car
    @car
  end

  def cdr
    @cdr
  end
end

class Array
  def to_list
    List.from_array self
  end
  
end
