angular.module 'app.controllers.calendar' []
.controller LYCalendar: <[$rootScope $scope $http LYService LYModel $sce]> ++ ($rootScope, $scope, $http, LYService, LYModel, $sce) ->
      committees = $rootScope.committees
      # XXX: unused.  use filter instead
      $scope.type = 'sitting'
      $rootScope.activeTab = \calendar

      $scope.committee = ({{committee}:entity}, col) ->
          return '院會' unless committee
          res = for c in committee
              """<img class="avatar small" src="http://avatars.io/50a65bb26e293122b0000073/committee-#{c}?size=small" alt="#{committees[c]}">""" + committees[c]
          $sce.trustAsHtml res.join ''

      $scope.chair = ({{chair}:entity}, col) ->
          return '' unless chair
          party = LYService.resolveParty chair
          avatar = CryptoJS.MD5 "MLY/#{chair}" .toString!
          $sce.trustAsHtml chair + """<img class="avatar small #party" src="http://avatars.io/50a65bb26e293122b0000073/#{avatar}?size=small" alt="#{chair}">"""

      /* comment out this block since we are not using ng-grid.
      $scope.onair = ({{date,time}:entity}) ->
          d = moment date .startOf \day
          return false unless +today is +d
          [start,end] = if time => (time.split \~ .map -> moment "#{d.format 'YYYY-MM-DD'} #it")
          else [entity.time_start,entity.time_end]map -> moment "#{d.format 'YYYY-MM-DD'} #it"
          start <= moment! <= end

      $scope.gridOptions = {+showFilter, +showColumnMenu, +showGroupPanel, +enableHighlighting,
      -groupsCollapsedByDefault, +inlineAggregate, +enableRowSelection} <<< do
          groups: <[primaryCommittee]>
          rowHeight: 65
          data: \calendar
          i18n: \zh-tw
          aggregateTemplate: """
          <div ng-click="row.toggleExpand()" ng-style="rowStyle(row)" class="ngAggregate" ng-switch on="row.field">
            <span ng-switch-when="primaryCommittee" class="ngAggregateText" ng-bind-html="row.label | committee"></span>
            <span ng-switch-default class="ngAggregateText">{{row.label CUSTOM_FILTERS}} ({{row.totalChildren()}} {{AggItemsLabel}})</span>
            <div class="{{row.aggClass()}}"></div>
          </div>
          """
          columnDefs:
            * field: 'primaryCommittee'
              visible: false
              displayName: \委員會
              width: 130
              cellTemplate: """
              <div ng-bind-html="row.getProperty(col.field) | committee"></div>
              """
            * field: 'committee'
              visible: false
              displayName: \委員會
              width: 130
              cellTemplate: """
              <div ng-bind-html="row.getProperty(col.field) | committee"></div>
              """
            * field: 'chair'
              displayName: \主席
              width: 130
              cellTemplate: """
              <div ng-bind-html="chair(row)"></div>
              """
            * field: 'date'
              cellFilter: 'date: mediumDate'
              width: 100px
              displayName: \日期
            * field: 'time'
              width: 100px
              displayName: \時間
              cellTemplate: """<div ng-class="{onair: onair(row)}"><div class="ngCellText">{{row.getProperty('time_start')}}-<br/>{{row.getProperty('time_end')}}</div></div>
              """
            * field: 'name'
              displayName: \名稱
              width: 320px
              cellTemplate: """<div class="ngCellText"><a ng-href="/sittings/{{row.getProperty('sitting_id')}}">{{row.getProperty(col.field)}}</a></div>"""
            * field: 'summary'
              displayName: \議程
              cellClass: \summary
              width: '*'

      $scope.$watch 'height' (->
          $ '.grid' .height $scope.height - 65
          options = $scope.gridOptions
          options.$gridServices.DomUtilityService.RebuildGrid options.$gridScope, options.ngGrid
      ), false
      */

      today = moment!startOf('day')
      $scope.weeksOpts = []
      # well, 49 is 7 weeks. I just pick the number for no reaseon.
      for i from 0 to 49 by 7
        do ->
          opt = {
            start: moment today .day 0 - i
            end: moment today .day 0 - i + 7
          }
          opt <<< label: opt.start.format "YYYY:  MM-DD" + ' to ' + opt.end.format "MM-DD"
        |> $scope.weeksOpts.push
      $scope.weeksOpts.unshift {
        start: moment today .add 'days', -1 # why not 0?
        end: moment today .add 'days', 1
        label: \今日
      }
      $scope.weeks = $scope.weeksOpts[0]
      getData = ->
        [start, end] = [$scope.weeks.start, $scope.weeks.end].map (.format "YYYY-MM-DD")
        $scope.start = $scope.weeks.start .format "YYYY-MM-DD"
        $scope.end = $scope.weeks.end .format "YYYY-MM-DD"
        {paging, entries} <- LYModel.get 'calendar' do
            params: do
                s: JSON.stringify date: 1, time: 1
                q: JSON.stringify do
                    date: $gt: start, $lt: end
                    type: $scope.type
                # XXX  shame on me
                l: 1000
        .success
        group = {}
        $scope.calendar = entries.map ->
          # XXX: why should we remove the timezone postfix 'Z' to let the statement works?
          # +(moment('2013-11-03T03:48:00.000Z')).startOf('day') === +(moment('2013-11-03T23:48:00.000Z')).startOf('day')
          it.date -= /Z/
          it <<< formatDate: moment(it.date).format('MMM Do, YYYY')
          it <<< primaryCommittee: it.committee?0 or 'YS'
          d = moment it.date .startOf \day
          [start, end] = if it.time => (it.time.split \~ .map -> moment "#{d.format 'YYYY-MM-DD'} #it")
          else [it.time_start, it.time_end]map -> moment "#{d.format 'YYYY-MM-DD'} #it"
          it <<< onair: +today is +d and start <= moment! <=end
          group[it.primaryCommittee] ?= []
          group[it.primaryCommittee].push it
        $scope.group = group
      $scope.$watch 'weeks', getData
      $scope.change = !(type) ->
          $scope.type = type
          getData!


