
require "chef/knife"
require "chef/knife/base_vsphere_command"

# Upload or download a file from a datastore
# VsphereDatastoreFile extends the BaseVspherecommand
class Chef::Knife::VsphereDatastoreFile < Chef::Knife::BaseVsphereCommand
  banner "knife vsphere datastore file"

  common_options

  option :local_file,
    long: "--local-file FILE",
    short: "-f",
    description: "Local file and path"

  option :remote_file,
    long: "--remote-file FILE",
    short: "-r",
    description: "Remote file and path"

  option :upload,
    long: "--upload-file",
    short: "-u",
    description: "Upload local file to remote"

  option :download,
    long: "--download-file",
    short: "-D",
    description: "Download remote file to local"

  # Main run method for datastore_file
  #
  def run
    $stdout.sync = true

    unless get_config(:upload) || get_config(:download)
      show_usage
      fatal_exit("You must specify either upload or download")
    end
    unless get_config(:local_file) && get_config(:remote_file)
      show_usage
      fatal_exit("You must specify both local-file and remote-file")
    end

    vim_connection
    datastore = find_datastore(@name_args[0])
    if get_config(:upload)
      datastore.upload(get_config(:remote_file), get_config(:local_file))
    elsif get_config(:download)
      datastore.download(get_config(:remote_file), get_config(:local_file))
    end
  end
end
