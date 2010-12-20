class PlmActionFlow < ActionFlow::Base
 
  # Put your mapping in Ruby objects standard initialize method
  def initialize
 
    # Start the flow with the initialization view
    start_with :init
    
    # End the flow on the qui view
    end_with :quit
    
    # Redirect the invalid flows to the index of
    # the current controller so the flow initializes
    # correctly
    redirect_invalid_flows :action => :index
    
    
    # Rescue potential errors
    upon :StandardError => :quit_with_error
    
    
    
    # Map the init step
    view_step :init do
    
      # Map some events to steps
      on :next => :hello_world  
      on :raise_error => :raise_error
      on :quit => :quit
      
      # Handle potential errors
      upon :StandardError => :quit_with_error
      
    end
    
    
    # Map the hello world step
    view_step :hello_world do
    
      # Map some events to steps
      on :hello_you_too => :quit
      on :back => :init
    
      # Handle potential errors
      upon :StandardError => :quit_with_error
      
    end
    
    
    # Map the error raising step
    action_step :raise_error do
      # Nothing to map, we'll throw an error
      # but the controller will rescue it.
    end
    
    
    # Map the hello world step
    action_step :quit_with_error do
      
      # Use this method as a step implementation
      method :show_error_and_quit
      
      # Map an event
      on :quit => :quit
      
    end
    
    
    # Map the quit step
    view_step :quit
  
  end

 
end