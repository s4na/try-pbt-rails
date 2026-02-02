class CommentsController < ApplicationController
  before_action :require_login
  before_action :set_post
  before_action :set_comment, only: :destroy
  before_action :authorize_comment, only: :destroy

  def create
    @comment = @post.comments.build(comment_params)
    @comment.user = current_user
    if @comment.save
      flash[:notice] = "コメントを投稿しました"
    else
      flash[:alert] = "コメントの投稿に失敗しました"
    end
    redirect_to @post
  end

  def destroy
    @comment.destroy
    flash[:notice] = "コメントを削除しました"
    redirect_to @post
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end

  def set_comment
    @comment = @post.comments.find(params[:id])
  end

  def authorize_comment
    unless @comment.user == current_user
      flash[:alert] = "この操作は許可されていません"
      redirect_to @post
    end
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
