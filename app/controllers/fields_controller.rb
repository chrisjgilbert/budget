class FieldsController < ApplicationController
  before_action :load_month
  before_action :load_field, only: %i[update destroy]

  def create
    label = params.dig(:field, :label).to_s.strip
    if label.blank?
      redirect_to month_path(@month), alert: "Field name is required."
      return
    end

    @month.fields.create!(
      key: Field.generate_key(label, @month),
      label: label,
      section: params.dig(:field, :section),
      behavior: params.dig(:field, :behavior),
      reset_on_new: ActiveModel::Type::Boolean.new.cast(params.dig(:field, :reset_on_new)) || false,
      value: 0,
      position: (@month.fields.maximum(:position) || -1) + 1
    )
    redirect_to month_path(@month)
  end

  def update
    attrs = {}
    attrs[:label]        = params.dig(:field, :label).to_s.strip     if params.dig(:field, :label)
    attrs[:behavior]     = params.dig(:field, :behavior)             if params.dig(:field, :behavior)
    attrs[:section]      = params.dig(:field, :section)              if params.dig(:field, :section)
    attrs[:reset_on_new] = ActiveModel::Type::Boolean.new.cast(params.dig(:field, :reset_on_new)) if params[:field]&.key?(:reset_on_new)
    if params.dig(:field, :value)
      attrs[:value] = params.dig(:field, :value).to_s.strip.presence || 0
    end
    @field.update!(attrs)
    redirect_to month_path(@month)
  end

  def destroy
    @field.destroy
    redirect_to month_path(@month)
  end

  private

  def load_month
    @month = Month.find(params[:month_id])
  end

  def load_field
    @field = @month.fields.find(params[:id])
  end
end
