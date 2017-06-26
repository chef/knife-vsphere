pipeline {
  agent {
    docker {
      reuseNode false
      args '-u root'
      // you'll need to change this for your environment.
      image 'localhost:5000/jjkeysv5'
    }
    
  }
  stages {
    stage('Pull down the ChefDK') {
      steps {
        sh '''apt-get update
apt-get install -y curl sudo git build-essential
curl -L https://chef.io/chef/install.sh | sudo bash -s -- -P chefdk -c current'''
      }
    }
    stage('Bundle') {
      steps {
        sh 'chef exec bundle install'
      }
    }
    stage('Checks') {
      steps {
        sh 'chef exec rake yard'
      }
    }
    stage('Lists') {
      steps {
        parallel(
          "vm": {
            sh 'chef exec bundle exec knife vsphere vm list'
            
          },
          "template": {
            sh 'chef exec bundle exec knife vsphere template list'
            
          },
          "datastore": {
            sh 'chef exec bundle exec knife vsphere datastore list'
            
          }
        )
      }
    }
    stage('Create') {
      steps {
        parallel(
          "linux": {
            sh 'chef exec bundle exec knife vsphere vm clone lin-knifevsphere-testing --template ubuntu16-template -f Linux --bootstrap --start --cips dhcp --dest-folder /  --cspec ubuntu --ssh-user admini --ssh-password admini --node-ssl-verify-mode none'
            
          },
          "windows": {
            sh 'chef exec bundle exec knife vsphere vm clone win-knifevsphere-testing --template windows2012R2 -f Windows --bootstrap --start --cips dhcp --dest-folder / --winrm-user "Administrator" --winrm-password "Admini@" --node-ssl-verify-mode none --disable-customization'
            
          }
        )
      }
    }
    stage('Delete') {
      steps {
        parallel(
          "linux": {
            sh 'chef exec bundle exec knife vsphere vm delete lin-knifevsphere-testing -P -y'
            
          },
          "windows": {
            sh 'chef exec bundle exec knife vsphere vm delete win-knifevsphere-testing -P -y'
            
          }
        )
      }
    }
  }
  triggers {
    pollSCM('H * * * *')
  }
}
