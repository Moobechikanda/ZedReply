class RenameZedreplyInstallationToAnansiflow < ActiveRecord::Migration[7.1]
  def up
    rename_branding_config('INSTALLATION_NAME')
    rename_branding_config('BRAND_NAME')
    GlobalConfig.clear_cache
  end

  def down
    restore_branding_config('INSTALLATION_NAME')
    restore_branding_config('BRAND_NAME')
    GlobalConfig.clear_cache
  end

  private

  def rename_branding_config(name)
    update_branding_config(name, 'ZedReply', 'AnansiFlow')
  end

  def restore_branding_config(name)
    update_branding_config(name, 'AnansiFlow', 'ZedReply')
  end

  def update_branding_config(name, from, to)
    config = InstallationConfig.find_by(name: name)
    config&.update!(value: to) if config&.value == from
  end
end
