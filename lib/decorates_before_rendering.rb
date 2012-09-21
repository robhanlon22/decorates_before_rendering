# -*- encoding : utf-8 -*-
require "decorates_before_rendering/version"
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/class/attribute'

# Decorates the specified fields. For instance, if you have
#
#   class StuffController < ApplicationController
#     include DecoratesBeforeRendering
#
#     decorates :thing_1, :thing_2
#   end
#
# @thing_1 and @thing_2 will be decorated right before a rendering occurs.
#
module DecoratesBeforeRendering
  module ClassMethods
    def decorates(*unsigiled_ivar_names)
      options = {}
      if unsigiled_ivar_names.last.instance_of?(::Hash)
        options = unsigiled_ivar_names.pop
      end

      self.__ivars_to_decorate__ ||= []
      self.__ivars_to_decorate__ << [ unsigiled_ivar_names.map { |i| "@#{i}" }, options ]
    end
  end

  def render(*args)
    __decorate_ivars__
    super(*args)
  end

private

  def __decorate_ivars__
    ivars_to_decorate = self.class.__ivars_to_decorate__

    return if ivars_to_decorate.nil? or ivars_to_decorate.empty?

    ivars_to_decorate.each do |ivar_names, options|
      ivar_names.each do |ivar_name|
        if ivar = instance_variable_get(ivar_name)
          decorator = (options[:with] || __decorator_for__(ivar)).decorate(ivar)
          instance_variable_set(ivar_name, decorator)
        end
      end
    end
  end

  def __decorator_for__(ivar)
    __decorator_name_for__(ivar).constantize
  end

  def __decorator_name_for__(ivar)
    "#{__model_name_for__(ivar)}Decorator"
  end

  def __model_name_for__(ivar)
    if ivar.respond_to?(:model_name)
      ivar
    elsif ivar.class.respond_to?(:model_name)
      ivar.class
    else
      raise ArgumentError, "#{ivar} does not have an associated model"
    end.model_name
  end

  def self.included(base)
    base.class_attribute :__ivars_to_decorate__, :instance_accessor => false
    base.extend ClassMethods
  end
end
