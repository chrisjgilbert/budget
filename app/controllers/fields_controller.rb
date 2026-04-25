class FieldsController < ApplicationController
  before_action :load_month
  before_action :load_field, only: %i[update destroy]

  def create
    label = params.dig(:field, :label).to_s.strip
    if label.blank?
      respond_to do |format|
        format.turbo_stream { head :unprocessable_content }
        format.html { redirect_to month_path(@month), alert: "Field name is required." }
      end
      return
    end

    @field = @month.fields.create!(
      key: Field.generate_key(label, @month),
      label: label,
      section: params.dig(:field, :section),
      behavior: params.dig(:field, :behavior),
      reset_on_new: ActiveModel::Type::Boolean.new.cast(params.dig(:field, :reset_on_new)) || false,
      value: 0,
      position: (@month.fields.maximum(:position) || -1) + 1
    )
    @month.fields.reload

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to month_path(@month) }
    end
  end

  def update
    @old_section = @field.section
    attrs = update_attrs
    # A value-only change on an otherwise-unmodified field is the autosave
    # path — Turbo Stream responses avoid replacing the input element so
    # we don't clobber the user's cursor mid-typing.
    @value_only = attrs.keys == [ :value ]
    @field.update!(attrs)
    @month.fields.reload

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to month_path(@month) }
    end
  end

  def destroy
    @section_id = @field.section
    @field.destroy
    @month.fields.reload

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to month_path(@month) }
    end
  end

  private

  def load_month
    @month = Month.find(params[:month_id])
  end

  def load_field
    @field = @month.fields.find(params[:id])
  end

  def update_attrs
    attrs = {}
    attrs[:label]        = params.dig(:field, :label).to_s.strip     if params.dig(:field, :label)
    attrs[:behavior]     = params.dig(:field, :behavior)             if params.dig(:field, :behavior)
    attrs[:section]      = params.dig(:field, :section)              if params.dig(:field, :section)
    attrs[:reset_on_new] = ActiveModel::Type::Boolean.new.cast(params.dig(:field, :reset_on_new)) if params[:field]&.key?(:reset_on_new)
    if params.dig(:field, :value)
      attrs[:value] = params.dig(:field, :value).to_s.strip.presence || 0
    end
    attrs
  end
end
