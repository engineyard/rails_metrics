class RailsMetricsController < ApplicationController
  respond_to :html

  # GET /metrics
  # GET /metrics.xml
  def index
    @metrics = scope_store(RailsMetrics.store)
    @metrics_count = @metrics.count
    @metrics = with_limit_and_offset(@metrics)
    respond_with(@metrics)
  end

  # GET /metrics/1
  # GET /metrics/1.xml
  def show
    @metric = find_store(params[:id])
    respond_with(@metric)
  end

  # DELETE /metrics/1
  # DELETE /metrics/1.xml
  def destroy
    @metric = find_store(params[:id])
    @metric.destroy
    flash[:notice] = "Metric ##{@metric.id} was deleted with success."
    redirect_to rails_metrics_path
  end

  # DELETE /metrics
  # DELETE /metrics.xml
  def destroy_all
    count = scope_store(RailsMetrics.store).delete_all
    flash[:notice] = "All #{count} selected metrics were deleted."
    redirect_to rails_metrics_path
  end

  protected

  def with_limit_and_offset(scope)
    @limit  = (params[:limit].presence || 50).to_i
    @offset = (params[:offset].presence || 0).to_i
    @metrics.limit(@limit).offset(@offset).all
  end

  def scope_store(store)
    @by_name = params[:by_name].presence
    store = store.by_name(@by_name) if @by_name

    @by_request_id = params[:by_request_id].presence
    store = store.by_request_id(@by_request_id) if @by_request_id

    @order_by = (valid_order_by? ? params[:order_by] : :latest).to_sym
    store = store.send(@order_by)

    store
  end

  def valid_order_by?
    RailsMetrics::Store::VALID_ORDERS.include?(params[:order_by]) 
  end

  def find_store(id)
    RailsMetrics.store.find(id)
  end
end