require 'spec_helper'
require 'tempfile'
require 'berkshelf'

describe ChefRelevantTests::ChangeDetectors::Berkshelf do
  let(:old_contents) { '' }
  let(:new_contents) { '' }

  before do
    old = Tempfile.new('oldberksfile')
    old.write(old_contents)
    old.close
    new = Tempfile.new('newberksfile')
    new.write(new_contents)
    new.close
    @old_berksfile = ::Berkshelf::Lockfile.from_file(old.path)
    @new_berksfile = ::Berkshelf::Lockfile.from_file(new.path)

    allow_any_instance_of(described_class)
      .to receive(:get_berksfiles_to_compare)
      .and_return([@old_berksfile, @new_berksfile])
  end

  describe 'when bumping a version' do
    let(:old_contents) { <<-BERKS }
DEPENDENCIES
  foo

GRAPH
  foo (0.1.0)
    bar (>= 0.0.0)
BERKS
    let(:new_contents) { <<-BERKS }
DEPENDENCIES
  foo

GRAPH
  foo (0.1.1)
    bar (>= 0.0.0)
BERKS

    it 'returns that cookbook' do
      expect(described_class.new('HEAD').changed_cookbooks).to eq(['foo'])
    end
  end

  describe 'when bumping a dependency of a cookbook' do
    let(:old_contents) { <<-BERKS }
DEPENDENCIES
  foo

GRAPH
  bar (0.1.0)
  foo (0.1.0)
    bar (>= 0.0.0)
BERKS
    let(:new_contents) { <<-BERKS }
DEPENDENCIES
  foo

GRAPH
  bar (0.1.1)
  foo (0.1.0)
    bar (>= 0.0.0)
BERKS

    it 'returns that cookbook' do
      expect(described_class.new('HEAD').changed_cookbooks).to eq(['bar', 'foo'])
    end
  end
end
