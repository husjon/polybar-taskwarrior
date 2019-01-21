#!/bin/bash

COUNT_OVERDUE=$(task +OVERDUE count)
COUNT_DUE_TODAY=$(task +PENDING +TODAY count)
COUNT_DUE_SOON=$(task +DUE +READY count)
COUNT_DUE_NEVER=$(task -DUE +READY count)

TASK_LIMIT=${TASK_LIMIT:-5}

task_list="task rc.report.list.sort=urgency- list limit:$TASK_LIMIT"

inform() {
    event_id=$1
    due_by=${2:-""}
    desc="$(task _get "$event_id.description")"
    project="$(task _get "$event_id.project")"
    due_date=$(task _get "$event_id.due")
    if [[ $project ]]; then
        project="[$project] "
    else
        project=""
    fi
    if [[ $due_date ]]; then
        if [[ $due_by == "overdue" ]]; then
            due=" is <b>overdue</b>"
        elif [[ $due_by ]]; then
            due=" is due by <b>$due_by</b>"
        else
            due=" is due by $due_date"
        fi
    else
        due=""
    fi
    notify-send -t 0 "taskwarrior" "$project<u>$desc</u>$due"
}

if [[ $1 == "events" ]]; then
    flavour_text=""

    if (($COUNT_OVERDUE > 0)); then
        time_restriction="+OVERDUE"
        flavour_text="overdue"
    elif (($COUNT_DUE_TODAY > 0)); then
        time_restriction="+DUE +TODAY"
        flavour_text="today"
    elif ((COUNT_DUE_SOON > 0)); then
        time_restriction="+DUE +READY"
    else
        time_restriction=""
    fi
    for event_id in $($task_list $time_restriction | head -n -1 | awk '/^[0-9]+/ {print $1}'); do
        inform $event_id $flavour_text
    done
    exit
fi

output() {
    (( $1 == 1 )) && tasks_string="task" || tasks_string="tasks"
    echo $1 $tasks_string $2
    exit 0
}

((COUNT_OVERDUE   > 0)) && output "${COUNT_OVERDUE}"   "overdue"
((COUNT_DUE_TODAY > 0)) && output "${COUNT_DUE_TODAY}" "due today"
((COUNT_DUE_SOON  > 0)) && output "${COUNT_DUE_SOON}"  "due soon"

((COUNT_OVERDUE + COUNT_DUE_TODAY + COUNT_DUE_SOON == 0)) && \
    output "${COUNT_DUE_NEVER}" "due some day"

output ""
