# Generated via
#  `rails generate hyrax:work BookChapter`

module Hyrax
  class BookChaptersController < SharedBehaviorsController
    # Adds Hyrax behaviors to the controller.

     include Hyrax::WorksControllerBehavior
     include Hyrax::BreadcrumbsForWorks
    self.curation_concern_type = ::BookChapter

    # Use this line if you want to use a custom presenter
    self.show_presenter = Hyrax::BookChapterPresenter
  end
end
