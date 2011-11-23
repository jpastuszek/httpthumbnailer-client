Feature: Thumbnailing images over HTTP with HTTPThumbniler server
  In order to retrive a set of thumbnails
  A user can use HTTPThumbnailerClient to performe calls to the server
  and retrive thumbnail data

  Scenario: Thumbnailing
    Given HTTPThumbniler server is listening at http://localhost:3100
    When I create a sweet new gem
    Then everyone should see how awesome I am
