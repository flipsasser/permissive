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
        return :global if scope.to_s == 'global'
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
        return :global if scope.to_s == 'global'
        scope = case scope
        when ActiveRecord::Base
          scope.class.name.to_s.tableize
        when Class
          scope.name.tableize
        when String, Symbol
          interpolate_scope(model, scope).to_s.tableize
        else
          :global
        end
        scope.to_s.gsub('/', '_').to_sym
      end
    end

    def can(*args)
      # if value
      #   to(name, value)
      # end
      args.each do |name|
        name = name.to_s.downcase.to_sym
        roles[@role].push(name) unless roles[@role].include?(name)
      end
    end

    def define_methods
      permission_setter = @options[:on] == :global ? 'permissions' : "#{@options[:on].to_s.singularize}_permissions"
      if model.instance_methods.include?("#{permission_setter}=")
        if !model.instance_methods.include?("#{permission_setter}_with_permissive=")
          model.class_eval <<-eoc
            def #{permission_setter}_with_permissive=(values)
              values ||= []
              if values.all? {|value| value.is_a?(String) || value.is_a?(Symbol)}
                can!(values, :reset => true, :on => #{@options[:on].inspect})
              else
                self.#{permission_setter}_without_permissive = values
              end
            end
            # alias_method_chain "#{permission_setter}=", :permissive
          eoc
        end
        model.alias_method_chain "#{permission_setter}=", :permissive
      else
        model.class_eval <<-eoc
          def #{permission_setter}=(values)
            values ||= []
            if values.all? {|value| value.is_a?(String) || value.is_a?(Symbol)}
              can!(values, :reset => true, :on => #{@options[:on].inspect})
            end
          end
        eoc
      end

      if model.column_names.include?('role')
        model.class_eval do
          def role=(role_name)
            if role_name
              self.permissions = self.class.permissions[:global].roles[role_name.to_s.downcase.to_sym]
            else
              self.permissions = []
            end
            write_attribute(:role, role_name.to_s.downcase.strip)
          end
        end
      else
        model.class_eval do
          def role=(role_name)
            self.permissions = self.class.permissions[:global].roles[role_name.to_s.downcase.to_sym]
          end
        end
      end
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
      permission_definition = Permissive::PermissionDefinition.define(model, @options.merge(:on => class_name), &block)
      permission_definition.define_methods
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

    def role(*names, &block)
      names.each do |name|
        @role = name.to_s.to_sym
        roles[@role] ||= []
        instance_eval(&block) if block_given?
        if model.column_names.include?('role') && !model.instance_methods.include?("is_#{name}?")
          model.class_eval <<-eoc
            def is_#{name}?
              role == #{name.to_s.downcase.inspect}
            end
          eoc
        end
      end
    end

    def roles
      @roles ||= {}
    end
  end
end