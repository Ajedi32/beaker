require 'spec_helper'

module Beaker
  describe CLI do
    let(:cli)      { Beaker::CLI.new }

    context 'execute!' do
      before :each do
       stub_const("Beaker::Logger", double().as_null_object )
        File.open("sample.cfg", "w+") do |file|
          file.write("HOSTS:\n")
          file.write("  myhost:\n")
          file.write("    roles:\n")
          file.write("      - master\n")
          file.write("    platform: ubuntu-x-x\n")
          file.write("CONFIG:\n")
        end
        allow( cli ).to receive(:setup).and_return(true)
        allow( cli ).to receive(:validate).and_return(true)
        allow( cli ).to receive(:provision).and_return(true)
      end

      describe "test fail mode" do
        it 'runs pre_cleanup after a failed pre_suite if using slow fail_mode' do
          options = cli.instance_variable_get(:@options)
          options[:fail_mode] = 'slow'
          cli.instance_variable_set(:@options, options)
          allow( cli ).to receive(:run_suite).with(:pre_suite, :fast).and_throw("bad test")
          allow( cli ).to receive(:run_suite).with(:tests, options[:fail_mode])
          allow( cli ).to receive(:run_suite).with(:post_suite).and_return(true)
          allow( cli ).to receive(:run_suite).with(:pre_cleanup).and_return(true)

          expect( cli ).to receive(:run_suite).exactly( 2 ).times
          expect{ cli.execute! }.to raise_error

        end

        it 'continues testing after failed test if using slow fail_mode' do
          options = cli.instance_variable_get(:@options)
          options[:fail_mode] = 'slow'
          cli.instance_variable_set(:@options, options)
          allow( cli ).to receive(:run_suite).with(:pre_suite, :fast).and_return(true)
          allow( cli ).to receive(:run_suite).with(:tests, options[:fail_mode]).and_throw("bad test")
          allow( cli ).to receive(:run_suite).with(:post_suite).and_return(true)
          allow( cli ).to receive(:run_suite).with(:pre_cleanup).and_return(true)

          expect( cli ).to receive(:run_suite).exactly( 4 ).times
          expect{ cli.execute! }.to raise_error

        end

        it 'stops testing after failed test if using fast fail_mode' do
          options = cli.instance_variable_get(:@options)
          options[:fail_mode] = 'fast'
          cli.instance_variable_set(:@options, options)
          allow( cli ).to receive(:run_suite).with(:pre_suite, :fast).and_return(true)
          allow( cli ).to receive(:run_suite).with(:tests, options[:fail_mode]).and_throw("bad test")
          allow( cli ).to receive(:run_suite).with(:pre_cleanup).and_return(true)

          expect( cli ).to receive(:run_suite).exactly( 3 ).times
          expect{ cli.execute! }.to raise_error

        end
      end

      describe "SUT preserve mode" do
        it 'cleans up SUTs post testing if tests fail and preserve_hosts = never' do
          options = cli.instance_variable_get(:@options)
          options[:fail_mode] = 'fast'
          options[:preserve_hosts] = 'never'
          cli.instance_variable_set(:@options, options)
          allow( cli ).to receive(:run_suite).with(:pre_suite, :fast).and_return(true)
          allow( cli ).to receive(:run_suite).with(:tests, options[:fail_mode]).and_throw("bad test")
          allow( cli ).to receive(:run_suite).with(:pre_cleanup).and_return(true)

          netmanager = double(:netmanager)
          cli.instance_variable_set(:@network_manager, netmanager)
          expect( netmanager ).to receive(:cleanup).once

          expect{ cli.execute! }.to raise_error

        end

        it 'cleans up SUTs post testing if no tests fail and preserve_hosts = never' do
          options = cli.instance_variable_get(:@options)
          options[:fail_mode] = 'fast'
          options[:preserve_hosts] = 'never'
          cli.instance_variable_set(:@options, options)
          allow( cli ).to receive(:run_suite).with(:pre_suite, :fast).and_return(true)
          allow( cli ).to receive(:run_suite).with(:tests, options[:fail_mode]).and_return(true)
          allow( cli ).to receive(:run_suite).with(:post_suite).and_return(true)
          allow( cli ).to receive(:run_suite).with(:pre_cleanup).and_return(true)

          netmanager = double(:netmanager)
          cli.instance_variable_set(:@network_manager, netmanager)
          expect( netmanager ).to receive(:cleanup).once

          expect{ cli.execute! }.to_not raise_error

        end


        it 'preserves SUTs post testing if no tests fail and preserve_hosts = always' do
          options = cli.instance_variable_get(:@options)
          options[:fail_mode] = 'fast'
          options[:preserve_hosts] = 'always'
          options[:log_dated_dir] = '.'
          options[:hosts_file] = 'sample.cfg'
          cli.instance_variable_set(:@options, options)
          allow( cli ).to receive(:run_suite).with(:pre_suite, :fast).and_return(true)
          allow( cli ).to receive(:run_suite).with(:tests, options[:fail_mode]).and_return(true)
          allow( cli ).to receive(:run_suite).with(:post_suite).and_return(true)
          allow( cli ).to receive(:run_suite).with(:pre_cleanup).and_return(true)
          cli.instance_variable_set(:@hosts, {})

          netmanager = double(:netmanager)
          cli.instance_variable_set(:@network_manager, netmanager)
          expect( netmanager ).to receive(:cleanup).never

          expect{ cli.execute! }.to_not raise_error

        end

        it 'preserves SUTs post testing if no tests fail and preserve_hosts = always' do
          options = cli.instance_variable_get(:@options)
          options[:fail_mode] = 'fast'
          options[:preserve_hosts] = 'always'
          cli.instance_variable_set(:@options, options)
          allow( cli ).to receive(:run_suite).with(:pre_suite, :fast).and_return(true)
          allow( cli ).to receive(:run_suite).with(:tests, options[:fail_mode]).and_throw("bad test")
          allow( cli ).to receive(:run_suite).with(:post_suite).and_return(true)
          allow( cli ).to receive(:run_suite).with(:pre_cleanup).and_return(true)

          netmanager = double(:netmanager)
          cli.instance_variable_set(:@network_manager, netmanager)
          expect( netmanager ).to receive(:cleanup).never

          expect{ cli.execute! }.to raise_error
        end

        it 'cleans up SUTs post testing if no tests fail and preserve_hosts = onfail' do
          options = cli.instance_variable_get(:@options)
          options[:fail_mode] = 'fast'
          options[:preserve_hosts] = 'onfail'
          cli.instance_variable_set(:@options, options)
          allow( cli ).to receive(:run_suite).with(:pre_suite, :fast).and_return(true)
          allow( cli ).to receive(:run_suite).with(:tests, options[:fail_mode]).and_return(true)
          allow( cli ).to receive(:run_suite).with(:post_suite).and_return(true)
          allow( cli ).to receive(:run_suite).with(:pre_cleanup).and_return(true)

          netmanager = double(:netmanager)
          cli.instance_variable_set(:@network_manager, netmanager)
          expect( netmanager ).to receive(:cleanup).once

          expect{ cli.execute! }.to_not raise_error

        end

        it 'preserves SUTs post testing if tests fail and preserve_hosts = onfail' do
          options = cli.instance_variable_get(:@options)
          options[:fail_mode] = 'fast'
          options[:preserve_hosts] = 'onfail'
          cli.instance_variable_set(:@options, options)
          allow( cli ).to receive(:run_suite).with(:pre_suite, :fast).and_return(true)
          allow( cli ).to receive(:run_suite).with(:tests, options[:fail_mode]).and_throw("bad test")
          allow( cli ).to receive(:run_suite).with(:post_suite).and_return(true)
          allow( cli ).to receive(:run_suite).with(:pre_cleanup).and_return(true)

          netmanager = double(:netmanager)
          cli.instance_variable_set(:@network_manager, netmanager)
          expect( netmanager ).to receive(:cleanup).never

          expect{ cli.execute! }.to raise_error

        end

        it 'cleans up SUTs post testing if tests fail and preserve_hosts = onpass' do
          options = cli.instance_variable_get(:@options)
          options[:fail_mode] = 'fast'
          options[:preserve_hosts] = 'onpass'
          cli.instance_variable_set(:@options, options)
          allow( cli ).to receive(:run_suite).with(:pre_suite, :fast).and_return(true)
          allow( cli ).to receive(:run_suite).with(:tests, options[:fail_mode]).and_throw("bad test")
          allow( cli ).to receive(:run_suite).with(:post_suite).and_return(true)
          allow( cli ).to receive(:run_suite).with(:pre_cleanup).and_return(true)

          netmanager = double(:netmanager)
          cli.instance_variable_set(:@network_manager, netmanager)
          expect( netmanager ).to receive(:cleanup).once

          expect{ cli.execute! }.to raise_error

        end

        it 'preserves SUTs post testing if no tests fail and preserve_hosts = onpass' do
          options = cli.instance_variable_get(:@options)
          options[:fail_mode] = 'fast'
          options[:preserve_hosts] = 'onpass'
          options[:log_dated_dir] = '.'
          options[:hosts_file] = 'sample.cfg'
          cli.instance_variable_set(:@hosts, {})
          cli.instance_variable_set(:@options, options)
          allow( cli ).to receive(:run_suite).with(:pre_suite, :fast).and_return(true)
          allow( cli ).to receive(:run_suite).with(:tests, options[:fail_mode]).and_return(true)
          allow( cli ).to receive(:run_suite).with(:post_suite).and_return(true)
          allow( cli ).to receive(:run_suite).with(:pre_cleanup).and_return(true)

          netmanager = double(:netmanager)
          cli.instance_variable_set(:@network_manager, netmanager)
          expect( netmanager ).to receive(:cleanup).never

          expect{ cli.execute! }.to_not raise_error
        end
      end

      describe "#preserve_hosts_file" do
        it 'removes the pre-suite/post-suite/tests and sets to []' do
          hosts =  make_hosts
          options = cli.instance_variable_get(:@options)
          options[:log_dated_dir] = Dir.mktmpdir
          File.open("sample.cfg", "w+") do |file|
            file.write("HOSTS:\n")
            hosts.each do |host|
              file.write("  #{host.name}:\n")
              file.write("    roles:\n")
              host[:roles].each do |role|
                file.write("      - #{role}\n")
              end
              file.write("    platform: #{host[:platform]}\n")
            end
            file.write("CONFIG:\n")
          end
          options[:hosts_file] = 'sample.cfg'
          options[:pre_suite] = ['pre1', 'pre2', 'pre3']
          options[:post_suite] = ['post1']
          options[:pre_cleanup] = ['preclean1']
          options[:tests] = ['test1', 'test2']

          cli.instance_variable_set(:@options, options)
          cli.instance_variable_set(:@hosts, hosts)

          preserved_file = cli.preserve_hosts_file
          hosts_yaml = YAML.load_file(preserved_file)
          expect(hosts_yaml['CONFIG'][:tests]).to be == []
          expect(hosts_yaml['CONFIG'][:pre_suite]).to be == []
          expect(hosts_yaml['CONFIG'][:post_suite]).to be == []
          expect(hosts_yaml['CONFIG'][:pre_cleanup]).to be == []
        end
      end

      describe 'hosts file saving when preserve_hosts should happen' do

        before :each do
          options = cli.instance_variable_get(:@options)
          options[:fail_mode] = 'fast'
          options[:preserve_hosts] = 'onpass'
          options[:hosts_file] = 'sample.cfg'
          cli.instance_variable_set(:@options, options)
          allow( cli ).to receive(:run_suite).with(:pre_suite, :fast).and_return(true)
          allow( cli ).to receive(:run_suite).with(:tests, options[:fail_mode]).and_return(true)
          allow( cli ).to receive(:run_suite).with(:post_suite).and_return(true)
          allow( cli ).to receive(:run_suite).with(:pre_cleanup).and_return(true)

          hosts = [
            make_host('petey', { :hypervisor => 'peterPan' }),
            make_host('hatty', { :hypervisor => 'theMadHatter' }),
          ]
          cli.instance_variable_set(:@hosts, hosts)

          netmanager = double(:netmanager)
          cli.instance_variable_set(:@network_manager, netmanager)
          expect( netmanager ).to receive(:cleanup).never


          allow( cli ).to receive( :print_env_vars_affecting_beaker )
          logger = cli.instance_variable_get(:@logger)
          expect( logger ).to receive( :send ).with( anything, anything ).ordered
          expect( logger ).to receive( :send ).with( anything, anything ).ordered
        end

        it 'executes without error' do
          options = cli.instance_variable_get(:@options)
          Dir.mktmpdir do |dir|
            options[:log_dated_dir] = File.absolute_path(dir)

            expect{ cli.execute! }.to_not raise_error
          end
        end

        it 'copies a file into the correct location' do
          options = cli.instance_variable_get(:@options)
          Dir.mktmpdir do |dir|
            options[:log_dated_dir] = File.absolute_path(dir)

            cli.execute!

            copied_hosts_file = File.join(File.absolute_path(dir), 'hosts_preserved.yml')
            expect( File.exists?(copied_hosts_file) ).to be_truthy
          end
        end

        it 'generates a valid YAML file when it copies' do
          options = cli.instance_variable_get(:@options)
          Dir.mktmpdir do |dir|
            options[:log_dated_dir] = File.absolute_path(dir)

            cli.execute!

            copied_hosts_file = File.join(File.absolute_path(dir), 'hosts_preserved.yml')
            expect{ YAML.load_file(copied_hosts_file) }.to_not raise_error
          end
        end

        it 'sets :provision to false in the copied hosts file' do
          options = cli.instance_variable_get(:@options)
          Dir.mktmpdir do |dir|
            options[:log_dated_dir] = File.absolute_path(dir)

            cli.execute!

            copied_hosts_file = File.join(File.absolute_path(dir), 'hosts_preserved.yml')
            yaml_content = YAML.load_file(copied_hosts_file)
            expect( yaml_content['CONFIG']['provision'] ).to be_falsy
          end
        end

        it 'sets the @options :hosts_preserved_yaml_file to the copied file' do
          options = cli.instance_variable_get(:@options)
          Dir.mktmpdir do |dir|
            options[:log_dated_dir] = File.absolute_path(dir)

            expect( options.has_key?(:hosts_preserved_yaml_file) ).to be_falsy
            cli.execute!
            expect( options.has_key?(:hosts_preserved_yaml_file) ).to be_truthy

            copied_hosts_file = File.join(File.absolute_path(dir), 'hosts_preserved.yml')
            expect( options[:hosts_preserved_yaml_file] ).to be === copied_hosts_file
          end
        end

        describe 'output text informing the user that re-use is possible' do

          it 'if unsupported, does not output extra text' do
            options = cli.instance_variable_get(:@options)
            Dir.mktmpdir do |dir|
              options[:log_dated_dir] = File.absolute_path(dir)
              copied_hosts_file = File.join(File.absolute_path(dir), options[:hosts_file])

              logger = cli.instance_variable_get(:@logger)
              expect( logger ).to receive( :send ).with( anything, "\nYou can re-run commands against the already provisioned SUT(s) by following these steps:\n").never
              expect( logger ).to receive( :send ).with( anything, "- change the hosts file to #{copied_hosts_file}").never
              expect( logger ).to receive( :send ).with( anything, '- use the --no-provision flag').never

              cli.execute!
            end
          end

          it 'if supported, outputs the text letting the user know they can re-use these hosts' do
            options = cli.instance_variable_get(:@options)
            Dir.mktmpdir do |dir|
              options[:log_dated_dir] = File.absolute_path(dir)
              copied_hosts_file = File.join(File.absolute_path(dir), options[:hosts_file])

              hosts = cli.instance_variable_get(:@hosts)
              hosts << make_host('fusion', { :hypervisor => 'fusion' })

              reproducing_cmd = "the faith of the people"
              allow( cli ).to receive( :build_hosts_preserved_reproducing_command ).and_return( reproducing_cmd )

              logger = cli.instance_variable_get(:@logger)
              expect( logger ).to receive( :send ).with( anything, "\nYou can re-run commands against the already provisioned SUT(s) with:\n").ordered
              expect( logger ).to receive( :send ).with( anything, reproducing_cmd).ordered

              cli.execute!
            end
          end

          it 'if supported && docker is a hypervisor, outputs text + the untested warning' do
            options = cli.instance_variable_get(:@options)
            Dir.mktmpdir do |dir|
              options[:log_dated_dir] = File.absolute_path(dir)
              copied_hosts_file = File.join(File.absolute_path(dir), options[:hosts_file])

              hosts = cli.instance_variable_get(:@hosts)
              hosts << make_host('fusion', { :hypervisor => 'fusion' })
              hosts << make_host('docker', { :hypervisor => 'docker' })

              reproducing_cmd = "the crow flies true says the shoe to you"
              allow( cli ).to receive( :build_hosts_preserved_reproducing_command ).and_return( reproducing_cmd )

              logger = cli.instance_variable_get(:@logger)
              expect( logger ).to receive( :send ).with( anything, "\nYou can re-run commands against the already provisioned SUT(s) with:\n").ordered
              expect( logger ).to receive( :send ).with( anything, '(docker support is untested for this feature. please reference the docs for more info)').ordered
              expect( logger ).to receive( :send ).with( anything, reproducing_cmd).ordered

              cli.execute!
            end
          end

          it 'if unsupported && docker is a hypervisor, no extra text output' do
            options = cli.instance_variable_get(:@options)
            Dir.mktmpdir do |dir|
              options[:log_dated_dir] = File.absolute_path(dir)
              copied_hosts_file = File.join(File.absolute_path(dir), options[:hosts_file])

              hosts = cli.instance_variable_get(:@hosts)
              hosts << make_host('docker', { :hypervisor => 'docker' })

              logger = cli.instance_variable_get(:@logger)
              expect( logger ).to receive( :send ).with( anything, "\nYou can re-run commands against the already provisioned SUT(s) with:\n").never
              expect( logger ).to receive( :send ).with( anything, '(docker support is untested for this feature. please reference the docs for more info)').never
              expect( logger ).to receive( :send ).with( anything, "- change the hosts file to #{copied_hosts_file}").never
              expect( logger ).to receive( :send ).with( anything, '- use the --no-provision flag').never

              cli.execute!
            end
          end


        end
      end
      describe '#build_hosts_preserved_reproducing_command' do

        it 'replaces the hosts file' do
          new_hosts_file  = 'john/deer/was/here.txt'
          command_to_sub  = 'p --log-level debug --hosts pants/of/plan.poo jam --jankies --flag-business'
          command_correct = "p --log-level debug --hosts #{new_hosts_file} jam --jankies --flag-business"

          answer = cli.build_hosts_preserved_reproducing_command(command_to_sub, new_hosts_file)
          expect( answer.start_with?(command_correct) ).to be_truthy
        end

        it 'doesn\'t replace an entry if no --hosts key is found' do
          command_to_sub  = 'p --log-level debug johnnypantaloons7 --jankies --flag-business'
          command_correct = 'p --log-level debug johnnypantaloons7 --jankies --flag-business'

          answer = cli.build_hosts_preserved_reproducing_command(command_to_sub, 'john/deer/plans.txt')
          expect( answer.start_with?(command_correct) ).to be_truthy
        end

        it 'removes any old --provision flags' do
          command_to_sub  = '--provision jam  --provision --jankies --flag-business'
          command_correct = 'jam --jankies --flag-business'

          answer = cli.build_hosts_preserved_reproducing_command(command_to_sub, 'can/talk/to/pigs.yml')
          expect( answer.start_with?(command_correct) ).to be_truthy
        end

        it 'removes any old --no-provision flags' do
          command_to_sub  = 'jam  --no-provision --jankoos --no-provision --flag-businesses'
          command_correct = 'jam --jankoos --flag-businesses'

          answer = cli.build_hosts_preserved_reproducing_command(command_to_sub, 'can/talk/to/bears.yml')
          expect( answer.start_with?(command_correct) ).to be_truthy
        end
      end
    end
  end
end
