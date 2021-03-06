require 'net/http'

class MailController < ApplicationController

  no_login_required
  skip_before_filter :verify_authenticity_token  

  def create
    @page = Page.find(params[:page_id])
    @page.request, @page.response = request, response

    config, part_page = config_and_page(@page)

    mail = Mail.new(part_page, config, params[:mailer])
    @page.last_mail = part_page.last_mail = mail
    process_mail(mail, config)

    if params[:submit_for_newsletters]
      # Add params[:mailer][:email] to newsletters subscriber list
      http = Net::HTTP.new('em-ailer.emsolutions.ca', 80)      
      resp, data = http.post('/t/r/s/jtuts/', "cm-jtuts-jtuts=#{params[:mailer][:email]}" , nil)
    end
    
    if mail.send
      redirect_to (config[:redirect_to] || "#{@page.url}#mail_sent?name=#{params[:mailer][:name]}")
    else
      render :text => @page.render
    end
  end
  
  private
  
  # Hook here to do additional things, like check a CAPTCHA
  def process_mail(mail, config)
  end

  def config_and_page(page)
    until page.part(:mailer) or (not page.parent)
      page = page.parent
    end
    string = page.render_part(:mailer)
    [(string.empty? ? {} : YAML::load(string).symbolize_keys), page]
  end

end