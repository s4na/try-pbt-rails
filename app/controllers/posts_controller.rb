class PostsController < ApplicationController
  before_action :require_login, except: [ :index, :show ]
  before_action :set_post, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_post, only: [ :edit, :update, :destroy ]

  def index
    @posts = Post.includes(:user).order(created_at: :desc)
  end

  def show
    @comment = Comment.new
  end

  def new
    @post = current_user.posts.build
  end

  def create
    @post = current_user.posts.build(post_params)
    if @post.save
      flash[:notice] = "記事を投稿しました"
      redirect_to @post
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @post.update(post_params)
      flash[:notice] = "記事を更新しました"
      redirect_to @post
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    flash[:notice] = "記事を削除しました"
    redirect_to posts_path
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def authorize_post
    unless @post.user == current_user
      flash[:alert] = "この操作は許可されていません"
      redirect_to @post
    end
  end

  def post_params
    params.require(:post).permit(:title, :body)
  end
end
