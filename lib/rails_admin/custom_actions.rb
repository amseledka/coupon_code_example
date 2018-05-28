require 'rails_admin/config/actions'
require 'rails_admin/config/actions/base'

module RailsAdmin
  module Config
    module Actions
      class BulkCreate < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :member do
          true
        end

        register_instance_option :visible? do
          authorized? && !bindings[:object].approved
        end

        register_instance_option :link_icon do
          'fa fa-copy'
        end

        register_instance_option :controller do
          Proc.new do
            @object.bulk_generate(5)
            flash[:success] = "You have created 5 objects: #{@abstract_model.pretty_name}."
            redirect_to back_or_index
          end
        end
      end
    end
  end
end
