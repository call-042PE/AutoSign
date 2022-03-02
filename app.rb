require_relative 'router'
require_relative 'app/controllers/controller'
require_relative 'app/repository/repository'

json_file = File.join(__dir__, "/app/data/tokens.json")
repository = Repository.new(json_file)
controller = Controller.new(repository)

router = Router.new(controller)
router.run
