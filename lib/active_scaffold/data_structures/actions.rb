# frozen_string_literal: true

class ActiveScaffold::DataStructures::Actions
  include Enumerable

  def initialize(*)
    @set = []
    add(*)
  end

  def exclude(*args)
    args.collect!(&:to_sym) # symbolize the args
    @set.reject! { |m| args.include? m } # reject all actions specified
  end

  def add(*args)
    args.each { |arg| @set << arg.to_sym unless @set.include? arg.to_sym }
  end
  alias << add

  def each(&)
    @set.each(&)
  end

  def include?(val)
    val.is_a?(Symbol) ? super : @set.any? { |item| item.to_s == val.to_s }
  end

  # swaps one element in the list with the other.
  # accepts arguments in any order. it just figures out which one is in the list and which one is not.
  def swap(one, two)
    if include? one
      exclude one
      add two
    else
      exclude two
      add one
    end
  end

  protected

  # called during clone or dup. makes the clone/dup deeper.
  def initialize_copy(from)
    @set = from.instance_variable_get(:@set).clone
  end
end
