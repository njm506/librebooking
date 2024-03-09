{function name=displayReservation}
    <div class="resource-display-reservation">
        {format_date date=$reservation->StartDate() key=res_popup_time timezone=$Timezone}
        - {format_date date=$reservation->EndDate() key=res_popup_time timezone=$Timezone}
        | {$reservation->GetUserName()}
        <div class="title">{$reservation->GetTitle()|default:$NoTitle}</div>
    </div>
{/function}

<div id="resource-display" class="resource-display row  bg-secondary bg-gradient text-white h-100">
    <div class="col-7 left-panel">
        <div class="resource-display-name">{$ResourceName}</div>

        <div class="resource-display-current">
            {if $AvailableNow}
                <div class="resource-display-available">{translate key=Available}</div>
            {else}
                <div class="resource-display-unavailable">{translate key=Unavailable}</div>
            {/if}

            {if $CurrentReservation != null}
                {call name=displayReservation reservation=$CurrentReservation}
            {/if}
        </div>

        <div class="left-panel-bottom">
            <div class="resource-display-heading">{translate key=NextReservation}</div>
            {if $NextReservation != null}
                {call name=displayReservation reservation=$NextReservation}
            {else}
                <div class="resource-display-reservation">{translate key=None}</div>
            {/if}

            {if $RequiresCheckin}
                <form role="form" method="post" id="formCheckin" action="{$smarty.server.SCRIPT_NAME}?action=checkin"
                    class="inline-block">
                    <input type="hidden" {formname key=REFERENCE_NUMBER} value="{$CheckinReferenceNumber}" />
                    <div class="resource-display-action" id="checkin"><i
                            class="bi bi-check-lg me-1"></i>{translate key=CheckIn}
                    </div>
                </form>
            {/if}
            <div class="resource-display-action" id="reservePopup"><i class="bi bi-plus"></i> {translate key=Reserve}
            </div>
        </div>
    </div>
    <div class="col-5 right-panel">
        <div class="date">{formatdate date=$ReservationDate key=schedule_daily timezone=$Timezone}</div>
        <div class="upcoming-reservations">
            <div class="resource-display-heading">{translate key=UpcomingReservations}</div>
            {if $UpcomingReservations|default:array()|count > 0}
                {foreach from=$UpcomingReservations item=r name=upcoming}
                    <div class="resource-display-upcoming">
                        {call name=displayReservation reservation=$r}
                    </div>
                    {if !$smarty.foreach.upcoming.last}
                        <hr class="upcoming-separator" />
                    {/if}
                {/foreach}
            {else}
                <div class="resource-display-none">{translate key=None}</div>
            {/if}
        </div>
    </div>

    <div id="reservation-box-wrapper">
    </div>
    <div id="reservation-box">
        <form role="form" method="post" id="formReserve" action="{$smarty.server.SCRIPT_NAME}?action=reserve">
            <div class="row margin-top-25">
                <div class="col-12">
                    <div id="validationErrors" class="validationSummary alert alert-danger d-none">
                        <ul>
                        </ul>
                    </div>
                    <div>
                        <table class="reservations">
                            <thead>
                                <tr>
                                    {foreach from=$DailyLayout->GetPeriods($ReservationDate, true) item=period}
                                        <td class="reslabel" colspan="{$period->Span()}">{$period->Label($ReservationDate)}
                                        </td>
                                    {/foreach}
                                </tr>
                            </thead>
                            <tbody>
                                <tr>
                                    {assign var=slots value=$DailyLayout->GetLayout($ReservationDate, $ResourceId)}
                                    {foreach from=$slots item=slot}
                                        {assign var="referenceNumber" value=""}
                                        {if $slot->IsReserved()}
                                            {assign var="class" value="reserved"}
                                            {assign var="referenceNumber" value=$slot->Reservation()->ReferenceNumber}
                                        {elseif $slot->IsReservable()}
                                            {assign var="class" value="reservable"}
                                            {if $slot->IsPastDate(Date::Now())}
                                                {assign var="class" value="pasttime"}
                                            {/if}
                                        {else}
                                            {assign var="class" value="unreservable"}
                                        {/if}
                                        {if $slot->HasCustomColor()}
                                            {assign var=color value='style="background-color:'|cat:$slot->Color()|cat:';color:'|cat:$slot->TextColor()|cat:';"'}
                                        {/if}
                                        <td colspan="{$slot->PeriodSpan()}" {$color} data-begin="{$slot->Begin()}"
                                            data-end="{$slot->End()}" class="slot {$class}"
                                            data-refnum="{$referenceNumber}">
                                            {$slot->Label($SlotLabelFactory)|escape|default:'&nbsp;'}</td>
                                    {/foreach}
                                </tr>
                            </tbody>
                        </table>
                    </div>

                    <div class="input-group input-group-lg">
                        <div class="input-group-text" id="email-addon"><i class="bi bi-envelope"></i></div>
                        <label for="emailAddress" class="visually-hidden">{translate key=Email}</label>
                        <input id="emailAddress" type="email" class="form-control" placeholder="{translate key=Email}"
                            aria-describedby="email-addon" required="required" {formname key=EMAIL} />
                    </div>
                </div>
            </div>
            <div class="row margin-top-25">
                <div class="col-6">
                    <div class="input-group input-group-lg has-feedback">
                        <div class="input-group-text" id="starttime-addon">
                            <i class="bi bi-clock"></i>
                        </div>
                        <select title="{translate key='BeginDate'}" class="form-control"
                            aria-describedby="starttime-addon" id="beginPeriod" {formname key=BEGIN_PERIOD}>
                            {foreach from=$slots item=slot}
                                {if $slot->IsReservable() && !$slot->IsPastDate($ReservationDate)}
                                    <option value="{$slot->Begin()}">{$slot->Begin()->Format($TimeFormat)}</option>
                                {/if}
                            {/foreach}
                        </select>
                    </div>
                </div>
                <div class="col-6">
                    <div class="input-group input-group-lg">
                        <div class="input-group-text" id="endtime-addon">
                            <i class="bi bi-clock"></i>
                        </div>
                        <select title="{translate key='EndDate'}" class="form-control input-lg"
                            aria-describedby="endtime-addon" id="endPeriod" {formname key=END_PERIOD}>
                            {foreach from=$slots item=slot}
                                {if $slot->IsReservable() && !$slot->IsPastDate($ReservationDate)}
                                    <option value="{$slot->End()}">{$slot->End()->Format($TimeFormat)}</option>
                                {/if}
                            {/foreach}
                        </select>
                    </div>
                </div>
            </div>

            {if $Terms != null}
                <div class="row col-12" id="termsAndConditions">
                    <div class="checkbox">
                        <input type="checkbox" id="termsAndConditionsAcknowledgement" {formname key=TOS_ACKNOWLEDGEMENT}
                            {if $TermsAccepted}checked="checked" {/if} />
                        <label for="termsAndConditionsAcknowledgement">{translate key=IAccept}</label>
                        <a href="{$Terms->DisplayUrl()}" style="vertical-align: middle"
                            target="_blank">{translate key=TheTermsOfService}</a>
                    </div>
                </div>
            {/if}

            {if $Attributes|default:array()|count > 0}
                <div class="row margin-top-25">
                    <div class="customAttributes col-12">
                        {foreach from=$Attributes item=attribute name=attributeEach}
                            {if $smarty.foreach.attributeEach.index % 2 == 0}
                                <div class="row">
                                {/if}
                                <div class="customAttribute col-6">
                                    {control type="AttributeControl" attribute=$attribute}
                                </div>
                                {if $smarty.foreach.attributeEach.index % 2 ==1}
                                </div>
                            {/if}
                        {/foreach}
                        {if $Attributes|default:array()|count % 2 == 1}
                            <div class="col-6">&nbsp;</div>
                        {/if}
                    </div>
                </div>
            {/if}

            <div class="mt-4">
                <div class="d-grid gap-2">
                    <input type="submit" class="action-reserve col-12 btn btn-primary"
                        value="{translate key=Reserve}" />
                    <a href="#" class="action-cancel btn btn-secondary" id="reserveCancel">{translate key=Cancel}</a>
                </div>
            </div>

            <input type="hidden" {formname key=RESOURCE_ID} value="{$ResourceId}" />
            <input type="hidden" {formname key=SCHEDULE_ID} value="{$ScheduleId}" />
            <input type="hidden" {formname key=TIMEZONE} value="{$Timezone}" />
            <input type="hidden" {formname key=BEGIN_DATE} value="{$ReservationDate}" />
        </form>
    </div>

</div>