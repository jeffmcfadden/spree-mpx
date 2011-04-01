Rails.application.routes.draw do
  # Add your extension routes here

  namespace "admin" do
    resource :mpx do
      member do
        post 'export'
      end
    end
  end
  
end
