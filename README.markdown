Permissive gives your ActiveRecord models granular permission support
=
Permissive makes it trivial to add complex permission granting and checking
to your applications using ActiveRecord. It combines a model-based permissions
system with bitmasking to create a flexible approach to maintaining permissions
on your models. It supports an easy-to-use set of methods for accessing and
determining permissions, including some fun metaprogramming.

Installation
-

1. Get yourself some code. You can install as a gem:

	`gem install permissive`

	or as a plugin:

	`script/plugin install git://github.com/flipsasser/permissive.git`

2. Generate a migration so you can get some sweet table action:

	`script/generate permissive_migration`

	`rake db:migrate`

Usage
-

First, define a few permissions on an ActiveRecord::Base subclass. You define them using the following simple, block-based API:

	class User < ActiveRecord::Base
		has_permissions do
			to :manage_games, 0
			to :control_rides, 1
			to :punch, 2
		end
	end

The best practice is to name them in a verb format that follows this pattern: "Object can `do_action_name`".

Permission values (the second argument in `to`) need to be int values counting up from zero. We use ints because Permissive uses bit
masking to keep permissions data compact and performant.

And that's all it takes to configure permissions! Now that we have them, let's grant them to a model or two:

	class Employee < ActiveRecord::Base
		has_permissions, :on => :companies do
			to :manage_games, 0
			to :control_rides, 1
			to :punch, 2
		end
		validates_presence_of :first_name, :last_name
	end

	class Company < ActiveRecord::Base
	  validates_presence_of :name
	end

Easy-peasy, right? Let's try granting a few permissions:

	@james = Employee.create(:first_name => 'James', :last_name => 'Brennan')
	@frigo = Employee.create(:first_name => 'Tommy', :last_name => 'Frigo')
	@adventureland = Company.create(:name => 'Adventureland')

	# Okay, let's do some granting. We'll start by scoping to a specific company.
	@james.can!(:manage_games, :on => @adventureland)

	# Now let's do some permission checking.
	@james.can?(:manage_games, :on => @adventureland) #=> true

	# We can also use the metaprogramming syntax:
	@james.can_manage_games_in! @adventureland
	@james.can_manage_games_in? @adventureland #=> true
	@james.can_control_rides_in? @adventureland #=> false

	# We can check for multiple permissions, too:
	@james.can?(:manage_games, :control_rides) #=> false
	# OR:
	@james.can_manage_games_and_control_rides?

	# Scoping can be done through any object
	@frigo.can!(:punch, :on => @james)
	@frigo.can_punch? @james #=> true

	# And the permissions aren't reciprocal
	@james.can_punch? @frigo #=> false

	# Of course, we can grant global (non-scoped) permissions, too:
	@frigo.can_control_rides!
	@frigo.can_control_rides? #=> true

	# And we can grant permissions global to a class:
	@frigo.can_control_rides_in! Company

	# BUT! Global permissions don't override scoped permissions.
	@frigo.can_control_rides_in?(@adventureland) #=> false

	# Likewise, scoped permissions don't bubble up globally:
	@james.can_manage_games? #=> false

	# And, last but not least, let's take all of those great permissions away:
	@james.revoke(:manage_games, :on => @adventureland)

	# We can revoke all permissions, in any scope, too:
	@frigo.revoke(:all)

	# And revoking does the fun meta thing, too:
	@frigo.cannot_punch!(@james)
	@frigo.can_punch? @james #=> flase

And that's it!

Scoping
-

Permissive supports scoping at the class-configuration level, which adds relationships to permitted objects:

	class Employee < ActiveRecord::Base
	  acts_as_permissive :scope => :company
	end

	@frigo.permissive_companies #=> [Company 1, Company 2]

Replacing Permissions
-

Sometimes you want to overwrite all previous permissions in a can! method. That's pretty easy: just add :reset => true to the options.

	@frigo.can!(:control_rides, :on => @adventureland, :reset => true)

Next Steps
-

There's a number of things I want to add to the permissive settings. At the moment, Permissive currently support scoping at the class level, BUT all it really does is add a `has_many` relationship. `@employee.can!(:do_anything)` will still work, as will `@employee.can!(:do_something, :on => @something_that_isnt_a_company)`. That's pretty confusing to me. Adding more granular permissions might be cooler:

	class Employee < ActiveRecord::Base
	  has_permissions do
	    on :companies
	    on :employees
	  end
	end

which might yield something like

	@employee.permissive_companies
	# and
	@employee.can_control_rides_in_company @adventureland

Let's add some OR-ing to the whole thing:

	@james.can_control_rides_or_manage_games_in? @adventureland

I'd also like to enable Permissive::Templates (pre-set permission groups, like roles):

	administrator = Permissive::Template.named('Administrator')
	@james.acts_like administrator

Next up! I currently use a manual reset to grant permissions through a controller. It would by great to DRY this stuff up and provide some decent path for moving permissions into HTML forms. Right now, it looks something like this:

	<%= check_box_tag("employee[permissions][]", Permissive::Permissions::CONTROL_RIDES, @employee.can_control_rides?) %> Control rides

.. and in the controller:

	def update
	  @employee.can!(params[:employees].delete(:permissions), :revert => true)
	  respond_to do |format|
	    ...
	  end
	end

Finally, I'd like to use the `grant_mask` support that exists on the Permissive::Permission model to control what people can or cannot allow others to do. This would necessitate one of two things - first, a quick way of iterating over a person's granting permissions, e.g.:

	<% current_user.grant_permissions.each do |permission| %>
	<!-- Do something! -->
	<% end %>

and second, write-time checking of grantor permissions. Something like this, maybe:

	def update
	  current_user.grant(params[:employees][:permissions], :to => @employee)
	end

which would allow the Permissive::Permission model to make sure whatever `current_user` is granting to @employee, they're **allowed** to grant to @employee.

And that's it! Like all of my projects, I extracted it from some live development - which means it, too, is still in development. So please feel free to contribute!

Copyright (c) 2009 Flip Sasser & Simon Parsons, released under the MIT license