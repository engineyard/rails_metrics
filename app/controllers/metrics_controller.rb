class MetricsController < ApplicationController
  respond_to :html

  # GET /metrics
  # GET /metrics.xml
  def index
    @metrics = scope_store(RailsMetrics.store).all
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
    respond_with(@metric)
  end

  protected

  def scope_store(store)
    @by_name = params[:by_name].presence
    store = store.by_name(@by_name) if @by_name

    @by_instrumenter = params[:by_instrumenter].presence
    store = store.by_instrumenter(@by_instrumenter) if @by_instrumenter

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