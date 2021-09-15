# frozen_string_literal: true

class BookmarksController < ApplicationController
  requires_login

  def create
    params.require(:post_id)

    RateLimiter.new(
      current_user, "create_bookmark", SiteSetting.max_bookmarks_per_day, 1.day.to_i
    ).performed!

    bookmark_manager = BookmarkManager.new(current_user)
    bookmark = bookmark_manager.create(
      post_id: params[:post_id],
      name: params[:name],
      reminder_type: params[:reminder_type],
      reminder_at: params[:reminder_at],
      for_topic: params[:for_topic] == "true",
      options: {
        auto_delete_preference: params[:auto_delete_preference] || 0
      }
    )

    if bookmark_manager.errors.empty?
      return render json: success_json.merge(id: bookmark.id)
    end

    render json: failed_json.merge(errors: bookmark_manager.errors.full_messages), status: 400
  end

  def destroy
    params.require(:id)
    result = BookmarkManager.new(current_user).destroy(params[:id])
    render json: success_json.merge(result)
  end

  def update
    params.require(:id)

    bookmark_manager = BookmarkManager.new(current_user)
    bookmark_manager.update(
      bookmark_id: params[:id],
      name: params[:name],
      reminder_type: params[:reminder_type],
      reminder_at: params[:reminder_at],
      options: {
        auto_delete_preference: params[:auto_delete_preference] || 0
      }
    )

    if bookmark_manager.errors.empty?
      return render json: success_json
    end

    render json: failed_json.merge(errors: bookmark_manager.errors.full_messages), status: 400
  end

  def toggle_pin
    params.require(:bookmark_id)

    bookmark_manager = BookmarkManager.new(current_user)
    bookmark_manager.toggle_pin(bookmark_id: params[:bookmark_id])

    if bookmark_manager.errors.empty?
      return render json: success_json
    end

    render json: failed_json.merge(errors: bookmark_manager.errors.full_messages), status: 400
  end
end
