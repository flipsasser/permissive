module Permissive
  module ActsAsPermissive
    def self.included(base)
      base.class_eval do
        # This is the core of the Permissive module. It allows you to define a
        # permissive model structure complete with :scope. This will dynamically
        # generate scoped, polymorphic relationships across one or more models.
        def self.acts_as_permissive(options = {})
          options.assert_valid_keys(:scope)
          has_many :permissions, :class_name => 'Permissive::Permission', :as => :permitted_object do
            def can!(*args)
              options = args.last.is_a?(Hash) ? args.pop : {}
              options.assert_valid_keys(:on, :reset)
              if options[:on]
                permission = proxy_owner.permissions.find_or_initialize_by_scoped_object_id_and_scoped_object_type(options[:on].id, options[:on].class.to_s)
              else
                permission = Permissive::Permission.find_or_initialize_by_permitted_object_id_and_permitted_object_type(proxy_owner.id, proxy_owner.class.to_s)
              end
              if options[:reset]
                permission.mask = 0
                permission.grant_mask = 0
              end
              args.flatten.each do |name|
                bit = bit_for(name)
                unless permission.mask & bit != 0
                  permission.mask = permission.mask | bit
                end
              end
              permission.save!
            end

            def can?(*args)
              options = args.last.is_a?(Hash) ? args.pop : {}
              bits = args.map{|name| bit_for(name) }
              # scope = nil
              # if options[:on]
              #   scope = scoped(:conditions => ['scoped_object_id = ? AND scoped_object_type = ?', options[:on].id, options[:on].class.to_s])
              # else
              #   scope = scoped(:conditions => ['scoped_object_id IS NULL AND scoped_object_type IS NULL'])
              # end
              # Skip the trip to the database if the proxy has been loaded up already...
              # TODO: Fix this per-scope ... somehow ... probably beyond the scope of this project.
              # if @loaded
              #   bits.all?{|bit| self.select{|permission| permission.mask & bit != 0} }
              # else
              on(options[:on]).count(:conditions => [bits.map { 'permissive_permissions.mask & ?' }.join(' AND '), *bits]) > 0
              # end
            end

            def revoke(*args)
              options = args.last.is_a?(Hash) ? args.pop : {}
              if args.length == 1 && args.first == :all
                on(options[:on]).destroy_all
              else
                bits = args.map{|name| bit_for(name) }
                on(options[:on]).each do |permission|
                  bits.each do |bit|
                    if permission.mask & bit
                      permission.mask = permission.mask ^ bit
                    end
                  end
                  permission.save!
                end
              end
            end
          end

          if options[:scope]
            scope_name = "permissive_#{options[:scope].to_s}"
            unless reflection = reflect_on_association(scope_name)
              # TODO: There's just no way this should be working. It's WAY too
              # fragile. We need support for something more intelligent here,
              # like an options hash that includes :scope_type.
              namespace = self.to_s.split('::')
              if namespace.length > 1
                namespace.pop
                class_name = namespace.join('::') 
              else
                class_name = ''
              end
              class_name << "::#{options[:scope].to_s.classify}"
              has_many scope_name, :through => :permissions, :source => :scoped_object, :source_type => class_name
            end
          end

          class_eval do
            # Pass calls to the instance down to its permissions collection
            #   e.g. current_user.can(:view_comments) will bubble to
            #        current_user.permissions.can(:view_comments)
            def can!(*args)
              permissions.can!(*args)
            end

            # Pass calls to the instance down to its permissions collection
            #   e.g. current_user.can(:view_comments) will bubble to
            #        current_user.permissions.can(:view_comments)
            def can?(*args)
              permissions.can?(*args)
            end

            def revoke(*args)
              permissions.revoke(*args)
            end

            def method_missing(method, *args)
              if method.to_s =~ /^can_([^\?]+)\?$/
                permissions = $1
                options = {}
                if permissions =~ /_on$/
                  permissions.chomp!('_on')
                  options[:on] = args.shift
                end
                permissions = permissions.split('_and_')
                if permissions.all? {|permission| Permissive::Permissions.hash.has_key?(permission.downcase.to_sym) }
                  class_eval <<-end_eval
                    def #{method}#{"(scope)" if options[:on]}
                      can?(#{[permissions, args].flatten.join(', ').inspect}#{", :on => scope" if options[:on]})
                    end
                  end_eval
                  return can?(*[permissions, options].flatten)
                end
              end
              super
            end
          end
        end
      end
    end
  end
end

if defined?(ActiveRecord::Base)
  ActiveRecord::Base.send :include, Permissive::ActsAsPermissive
end