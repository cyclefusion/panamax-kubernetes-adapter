require 'spec_helper'

describe KubernetesAdapter::Models::Service do

  let(:attrs) do
    {
      name: 'foo',
      source: 'bar',
      command: '/bin/bash',
      ports: [{ port: 8080 }],
      expose: [9090],
      environment: [{ variable: 'PASSWORD', value: 'password' }],
      volumes: [{ path: '/a/b' }],
      links: [{ name: 'other', alias: 'db' }],
      deployment: { count: 10 }
    }
  end

  it { is_expected.to respond_to(:name) }
  it { is_expected.to respond_to(:source) }
  it { is_expected.to respond_to(:command) }
  it { is_expected.to respond_to(:ports) }
  it { is_expected.to respond_to(:expose) }
  it { is_expected.to respond_to(:environment) }
  it { is_expected.to respond_to(:volumes) }
  it { is_expected.to respond_to(:links) }
  it { is_expected.to respond_to(:deployment) }

  describe '#initialize' do

    context 'when no attrs are specified' do

      it 'initializes an empty object' do
        service = described_class.new

        expect(service.name).to be_nil
        expect(service.source).to be_nil
        expect(service.command).to be_nil
        expect(service.ports).to eq []
        expect(service.expose).to eq []
        expect(service.environment).to eq []
        expect(service.volumes).to eq []
        expect(service.links).to eq []
        expect(service.deployment).to eq({})
      end
    end

    context 'when attrs are specified' do

      it 'initializes the service with the attrs' do
        service = described_class.new(attrs)

        expect(service.name).to eq attrs[:name]
        expect(service.source).to eq attrs[:source]
        expect(service.command).to eq attrs[:command]
        expect(service.ports).to eq attrs[:ports]
        expect(service.expose).to eq attrs[:expose]
        expect(service.environment).to eq attrs[:environment]
        expect(service.volumes).to eq attrs[:volumes]
        expect(service.links).to eq attrs[:links]
        expect(service.deployment).to eq attrs[:deployment]
      end
    end
  end

  describe '#name' do

    let(:name) { 'fOO-3.4_latest' }

    subject { described_class.new(name: name) }

    it 'sanitizes the service name' do
      expect(subject.name).to eq 'foo-3-4-latest'
    end
  end

  describe '#links' do

    using KubernetesAdapter::StringExtensions

    let(:link) { { name: 'fO_o', alias: 'db' } }

    subject { described_class.new(links: [link]) }

    it 'sanitizes the service name in the links' do
      links = subject.links

      expect(links.count).to eq 1
      expect(links.first[:name]).to eq link[:name].sanitize
    end
  end

  describe '#scale' do

    context 'when a deployment hash has been specified' do

      let(:count) { 10 }
      subject { described_class.new(deployment: { count: count }) }

      it 'returns the deployment count' do
        expect(subject.scale).to eq count
      end

      context 'when deployment count is a string' do

        let(:count) { '10' }

        it 'returns the deployment count as an integer' do
          expect(subject.scale).to eq count.to_i
        end
      end
    end

    context 'when no deployment hash has been specified' do
      it 'returns the deployment count' do
        expect(subject.scale).to eq 1
      end
    end
  end

  describe '#min_port' do

    subject { described_class.new(expose: expose, ports: ports) }

    context 'when the min port is in the expose array' do

      let(:expose) { [2, 1, 3] }
      let(:ports) { [ { hostPort: 4, containerPort: 5 } ] }

      it 'returns the lowest numbered port' do
        expect(subject.min_port).to eq(hostPort: 1, containerPort: 1)
      end
    end

    context 'when the min port is in the ports array' do

      let(:expose) { [2, 5, 3] }

      context 'when the hostPort has been set' do

        let(:ports) { [ { hostPort: 4, containerPort: 1 } ] }

        it 'returns the lowest numbered port' do
          expect(subject.min_port).to eq(hostPort: 4, containerPort: 1)
        end
      end

      context 'when the hostPort has NOT been set' do

        let(:ports) { [ { containerPort: 1 } ] }

        it 'returns the lowest numbered port' do
          expect(subject.min_port).to eq(hostPort: 1, containerPort: 1)
        end
      end
    end

    context 'when there are no exposed or mapped ports' do

      let(:expose) { [] }
      let(:ports) { [] }

      it 'returns nil' do
        expect(subject.min_port).to be_nil
      end
    end
  end
end
