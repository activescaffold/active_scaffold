# Bugfix: building an sti model from an association fails
# https://rails.lighthouseapp.com/projects/8994-ruby-on-rails/tickets/6306-collection-associations-build-method-not-supported-for-sti
ActiveRecord::Reflection::AssociationReflection.class_eval do
  def build_association(*opts)
    col = klass.inheritance_column.to_sym
    if !col.nil? && opts.first.is_a?(Hash) && (opts.first.symbolize_keys[col])
      sti_model = opts.first.delete(col)
      sti_model.to_s.camelize.constantize.new(*opts)
    else
      klass.new(*opts)
    end
  end
end