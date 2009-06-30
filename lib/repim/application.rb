require "repim/random"

module Repim
  module Application
    def self.included(base)
      base.cattr_accessor :user_klass
      base.cattr_accessor :login_template
      base.cattr_accessor :with_single_access
      base.user_klass = (User rescue nil) # assign nil when LoadError and/or ConstMissing
      base.login_template = "sessions/new"
      base.with_single_access = (base.user_klass.column_names.include?('single_access_token') rescue false)

      base.before_filter :authenticate
      [:current_user, :signed_in?, :logged_in?].each do |method|
        base.helper_method method
        base.hide_action method
      end
    end

    def signed_in?; !!current_user ; end
    alias logged_in? signed_in?

    def current_user
      return nil if @__current_user__ == false
      return @__current_user__ if @__current_user__
      @__current_user__ ||= (user_from_session || false)
      current_user # call again
    end

    private
    def authenticate
      signed_in? || access_denied("Login required.")
    end
    alias login_required authenticate

    def access_denied(message = nil)
      store_location
      flash[:error] = message if message
      render :template => login_template, :status => :unauthorized
    end

    def store_location
      session[:return_to] = request.request_uri if request.get?
    end

    def current_user=(user)
      @__current_user__ = user
      if self.class.with_single_access
        # TODO Rails2.3以降で利用するか、もう少しセキュアなランダムを作成できるようにしたほうがよい
        user.single_access_token = Repim::Random.friendly_token
        session[:single_access_token] = user.single_access_token
        user.save(false)
      else
        session[:user_id] = user.id
      end
    end

    def user_from_session
      if self.class.with_single_access
        session[:single_access_token] && user_klass.find_by_single_access_token(session[:single_access_token])
      else
        session[:user_id] && user_klass.find_by_id(session[:user_id])
      end
    end

    def redirect_back_or(default)
      redirect_to(session[:return_to] || default)
    end
  end
end
