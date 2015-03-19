require 'spec_helper_acceptance'

describe "my tests" do

  # an example using the beaker DSL
  # use http://www.rubydoc.info/github/puppetlabs/beaker/Beaker/DSL
  it "should say hello!" do
    result = shell( 'echo hello' )
    expect(result.stdout).to match(/hello/)
  end

  # an example using Serverspec
  # use http://serverspec.org/resource_types.html
  describe package('puppet') do
    it { should be_installed }
  end

  it "can create and confirm a file" do
    shell( 'rm -f demo.txt' )
    create_remote_file(default, 'demo.txt', 'foo\nfoo\nfoo\n')
    shell( 'grep foo demo.txt' )
    shell( 'grep bar demo.txt', :acceptable_exit_codes => [1] )
  end

  it "should be able to apply manifests" do
    manifest_1 = "user {'foo':
          ensure => present,}"
    manifest_2 = "user {'foo':
          ensure => absent,}"
    manifest_3 = "user {'root':
          ensure => present,}"
    apply_manifest( manifest_1, :expect_changes => true )
    apply_manifest( manifest_2, :expect_changes => true )
    apply_manifest( manifest_3 )
  end

  describe service('sshd') do
    it { should be_running }
  end

  describe user('root') do
    it { should exist }
  end

  describe user('foo') do
    it { should_not exist }
  end

  context "can use both serverspec and Beaker DSL" do

    it "can create a file" do
      shell( 'rm -f /tmp/demo.txt' )
      manifest = "file {'demofile':
        path    => '/tmp/demo.txt',
        ensure  => present,
        mode    => 0640,
        content => \"this is my file.\",
      }"
      apply_manifest(manifest, :expect_changes => true)
    end

    describe file('/tmp/demo.txt') do
      it { should be_file }
    end

    describe file('/tmp/demo.txt') do
      it { should contain 'this is my file.' }
    end
  end


end