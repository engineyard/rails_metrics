class RailsMetricsController < ApplicationController
  respond_to :html

  # GET /rails_metrics
  def index
    @metrics = order_scopes(RailsMetrics.store.requests)
    @metrics_count = @metrics.count
    @metrics = with_pagination(@metrics)
    respond_with(@metrics)
  end

  # GET /rails_metrics/1/chart
  def chart
    @metrics = RailsMetrics.store.earliest.by_request_id(params[:id]).all
    @request = RailsMetrics.store.mount_tree(@metrics.reverse)
    respond_with(@metrics)
  end

  # GET /rails_metrics
  def all
    @metrics = all_scopes(RailsMetrics.store)
    @metrics_count = @metrics.count
    @metrics = with_pagination(@metrics)
    respond_with(@metrics)
  end

  # GET /rails_metrics/1
  def show
    @metric = find_store(params[:id])
    respond_with(@metric)
  end

  # DELETE /rails_metrics/1
  def destroy
    @metric = find_store(params[:id])
    @metric.destroy
    flash[:notice] = "Metric ##{@metric.id} was deleted with success."
    respond_with(@metric, :location => rails_metrics_path)
  end

  # DELETE /rails_metrics/destroy_all
  def destroy_all
    count = all_scopes(RailsMetrics.store).send(RailsMetrics::ORM.delete_all)
    flash[:notice] = "All #{count} selected metrics were deleted."
    redirect_to rails_metrics_path
  end

  protected

  def with_pagination(scope)
    @limit  = (params[:limit].presence || 50).to_i
    @offset = (params[:offset].presence || 0).to_i
    if scope.respond_to?(:limit)
      scope.limit(@limit).offset(@offset).all
    else
      scope.all(:limit => @limit, :offset => @offset)
    end
  end

  def by_scopes(store)
    @by_name = params[:by_name].presence
    store = store.by_name(@by_name) if @by_name
    store
  end

  def order_scopes(store)
    @order_by = (valid_order_by? ? params[:order_by] : :latest).to_sym
    store = store.send(@order_by)
  end

  def all_scopes(store)
    order_scopes(by_scopes(store))
  end

  def valid_order_by?
    RailsMetrics::Store::VALID_ORDERS.include?(params[:order_by]) 
  end

  def find_store(id)
    RailsMetrics.store.send(RailsMetrics::ORM.primary_key_finder, id)
  end
end