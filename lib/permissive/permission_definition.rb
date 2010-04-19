# TODO: Abstract this module more later
module Permissive
  class PermissionDefinition
    class << self
      def define(model, options, &block)
        options.assert_valid_keys(:on)
        options = {:on => :global}.merge(options)

        unless options[:on] == :global
          options[:on] = normalize_scope(model, options[:on])
        end
        permission_definition = model.permissions[options[:on]] ||= Permissive::PermissionDefinition.new(model, options)
        if block_given?
          permission_definition.instance_eval(&block)
        end
        permission_definition
      end

      def interpolate_scope(model, scope)
        attempted_scope = scope.to_s.singularize.classify
        model_module = model.name.to_s.split('::')
        model_module.pop
        model_module = model_module.join('::')
        if (model_module.blank? ? Object : Object.const_get(model_module)).const_defined?(attempted_scope)
          [model_module, attempted_scope].join('::')
        else
          scope.to_s.classify
        end
      end

      def normalize_scope(model, scope)
        case scope
        when Class
          scope.name.tableize
        when String, Symbol
          interpolate_scope(model, scope).to_s.tableize
        else
          :global
        end.to_s.gsub('/', '_').to_sym
      end
    end

    def can(name, value = nil)
      if value
        to(name, value)
      end
      name = name.to_s.downcase.to_sym
      roles[@role].push(name) unless roles[@role].include?(name)
    end

    def initialize(model, options = {})
      options.assert_valid_keys(:on)
      @options = options
      @model = model.name
    end

    def model
      @model.constantize
    end

    def on(class_name, &block)
      Permissive::PermissionDefinition.define(model, @options.merge(:on => class_name), &block)
    end

    def permission(name, value)
      unless value.is_a?(Numeric)
        raise Permissive::PermissionError.new("Permissions must be integers or longs. Strings, symbols, and floats are not currently supported.")
      end
      permissions[name.to_s.downcase.to_sym] = 2 ** value
    end
    alias :to :permission

    def permissions
      @permissions ||= {}
    end

    def role(name, &block)
      @role = name.to_s.to_sym
      roles[@role] ||= []
      instance_eval(&block)
      unless model.instance_methods.include?('role=')
        model.class_eval do
          def role=(role_name)
            self.permissions = self.class.permissions[:global].roles[role_name.to_s.downcase.to_sym]
          end
        end
      end
    end

    def roles
      @roles ||= {}
    end
  end
end