module DropboxHelper
  def get_name(path)
    require 'pathname'
    Pathname.new(path).basename.to_s
  end
  def get_file(path)
    puts path
    render :text => get_file_url(path)
  end

  def get_file_url(path)
    @dbclient = session[:dbclient]
    a = @dbclient.media(path)
    puts "DEBUG: a-", a
    url = a["url"]
    puts "DEBUG: url -", url
    return url
  end

  def get_dropbox_file_list(root_path)
    client = session[:dbclient]
    if !client.nil?
      metainfo = client.metadata(root_path)
      file_list = metainfo["contents"]
      ret_list = []
      file_list.each do |f|
        if f["is_dir"] then
        ret_list << {:name => get_name(f["path"]), :path => f["path"], :is_dir => f["is_dir"]}
        else
        puts "DEBUG - ", f
        ret_list << {:name => get_name(f["path"]), :path => f["path"], :is_dir => f["is_dir"], :url => get_file_url(f["path"])}
        end
      end
    else
      ret_list = []
    end
    return ret_list
  end


end
