class DirectoryScanner

  def initialize
    @fileAction = nil
    @dirAction = nil
  end

  def on_file(&action)
    @fileAction = action
  end
 
  def on_dir(&action)
    @dirAction = action
  end
 
  def directories_in_parent(parentPath)
    directories = []
    Dir.open(parentPath) do |dir|
      for file in dir
        next if file == '.';
        next if file == '..';
        path = parentPath + File::Separator + file
        if File.directory? path
          directories << file
        end
      end
    end 
    
    directories 
  end
 
  def scan_subtree(parentPath)
    Dir.open(parentPath) do |dir|
      for file in dir
        next if file == '.';
        next if file == '..';
        path = parentPath + File::Separator + file
        if File.directory? path
          @dirAction.call(file, path) unless @dirAction.nil?
          scan_subtree(path)
        else
          @fileAction.call(file, path) unless @fileAction.nil?
        end
      end
    end
  end

end
