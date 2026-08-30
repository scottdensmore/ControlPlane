#!/usr/bin/env ruby
# Adds ControlPlaneTests + ControlPlaneUITests targets and wires the shared scheme.
require 'xcodeproj'
require 'pathname'

ROOT = Pathname.new(__dir__).parent
PROJECT_PATH = ROOT + 'ControlPlane.xcodeproj'
SCHEME_PATH = ROOT + 'ControlPlane.xcodeproj/xcshareddata/xcschemes/ControlPlane.xcscheme'

project = Xcodeproj::Project.open(PROJECT_PATH.to_s)
app_target = project.targets.find { |t| t.name == 'ControlPlane' }
abort('ControlPlane target not found') unless app_target

# Remove prior attempts
%w[ControlPlaneTests ControlPlaneUITests].each do |name|
  existing = project.targets.find { |t| t.name == name }
  existing.remove_from_project if existing
  group = project.main_group.children.find { |c| c.respond_to?(:name) && c.name == name }
  group.remove_from_project if group
end

def add_sources(project, group, target, paths)
  paths.each do |rel|
    ref = group.new_file(rel)
    target.add_file_references([ref])
  end
end

# --- Unit test target ---
unit = project.new_target(:unit_test_bundle, 'ControlPlaneTests', :osx, '14.5')
unit_group = project.main_group.new_group('ControlPlaneTests', 'ControlPlaneTests')
unit_sources = Dir[ROOT.join('ControlPlaneTests/*.m').to_s].map { |p| Pathname.new(p).relative_path_from(ROOT).to_s }
add_sources(project, unit_group, unit, unit_sources)

unit.add_dependency(app_target)
unit.frameworks_build_phases.clear
['XCTest.framework', 'Cocoa.framework', 'Foundation.framework'].each do |fw|
  # XCTest is linked automatically for unit_test_bundle; ensure Cocoa for AppKit types
end

unit.build_configurations.each do |config|
  config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '14.5'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.scottdensmore.ControlPlaneTests'
  config.build_settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/ControlPlane.app/Contents/MacOS/ControlPlane'
  config.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
  config.build_settings['HEADER_SEARCH_PATHS'] = ['$(SRCROOT)/Source', '$(inherited)']
  config.build_settings['CLANG_ENABLE_OBJC_ARC'] = 'YES'
  config.build_settings['CODE_SIGN_IDENTITY'] = '-'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = [
    '$(inherited)',
    '@executable_path/../Frameworks',
    '@loader_path/../Frameworks'
  ]
end

# --- UI test target ---
ui = project.new_target(:ui_test_bundle, 'ControlPlaneUITests', :osx, '14.5')
ui_group = project.main_group.new_group('ControlPlaneUITests', 'ControlPlaneUITests')
ui_sources = Dir[ROOT.join('ControlPlaneUITests/*.m').to_s].map { |p| Pathname.new(p).relative_path_from(ROOT).to_s }
add_sources(project, ui_group, ui, ui_sources)
ui.add_dependency(app_target)

ui.build_configurations.each do |config|
  config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '14.5'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.scottdensmore.ControlPlaneUITests'
  config.build_settings['TEST_TARGET_NAME'] = 'ControlPlane'
  config.build_settings['CLANG_ENABLE_OBJC_ARC'] = 'YES'
  config.build_settings['CODE_SIGN_IDENTITY'] = '-'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
end

project.save

# Wire scheme TestAction
scheme = Xcodeproj::XCScheme.new(SCHEME_PATH.to_s)
# Clear and re-add testables
scheme.test_action.build_configuration = 'Debug'

# Build ControlPlaneTests + UITests for testing
entry_unit = Xcodeproj::XCScheme::BuildAction::Entry.new(unit)
entry_unit.build_for_testing = true
entry_unit.build_for_running = false
entry_unit.build_for_profiling = false
entry_unit.build_for_archiving = false
entry_unit.build_for_analyzing = false
scheme.build_action.add_entry(entry_unit)

entry_ui = Xcodeproj::XCScheme::BuildAction::Entry.new(ui)
entry_ui.build_for_testing = true
entry_ui.build_for_running = false
entry_ui.build_for_profiling = false
entry_ui.build_for_archiving = false
entry_ui.build_for_analyzing = false
scheme.build_action.add_entry(entry_ui)

testable_unit = Xcodeproj::XCScheme::TestAction::TestableReference.new(unit)
testable_ui = Xcodeproj::XCScheme::TestAction::TestableReference.new(ui)
scheme.test_action.add_testable(testable_unit)
scheme.test_action.add_testable(testable_ui)

# Disable aggressive malloc debugging during tests (breaks XCTest host sometimes)
scheme.launch_action.command_line_arguments.clear if scheme.launch_action.respond_to?(:command_line_arguments)

scheme.save!
puts "Added ControlPlaneTests + ControlPlaneUITests and updated scheme."
