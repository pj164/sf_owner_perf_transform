{{ config(materialized='table') }}
with opportunity as (

    select *
    from  {{ env_var('db_name') }}.{{ env_var('db_schema') }}.opportunity

), salesforce_user as (

    select *
    from {{ env_var('db_name') }}.{{ env_var('db_schema') }}.user

), account as (

    select *
    from {{ env_var('db_name') }}.{{ env_var('db_schema') }}.account

), add_fields as (

    select
      opportunity.*,
      account.accountnumber,
      account.accountsource,
      account.industry,
      account.name as account_name,
      account.numberofemployees,
      account.type as account_type,
      opportunity_owner.userroleid as opportunity_owner_id,
      opportunity_owner.username as opportunity_owner_name,
      opportunity_owner.city  as opportunity_owner_city,
      opportunity_owner.state as opportunity_owner_state,
      opportunity_manager.managerid as opportunity_manager_id,
      opportunity_manager.username as opportunity_manager_name,
      opportunity_manager.city opportunity_manager_city,
      opportunity_manager.state as opportunity_manager_state,
      case
        when opportunity.iswon then 'Won'
        when not opportunity.iswon and opportunity.isclosed then 'Lost'
        when not opportunity.isclosed and lower(opportunity.forecastcategory) in ('pipeline','forecast','bestcase') then 'Pipeline'
        else 'Other'
      end as status,
      case when opportunity.createddate__t >= date_trunc('month', current_date)   then amount else 0 end as created_amount_this_month,
      case when extract(quarter from opportunity.createddate__t) = extract(quarter from current_date) then amount else 0 end as created_amount_this_quarter,
      case when opportunity.createddate__t >= date_trunc('month', current_date)   then 1 else 0 end as created_count_this_month,
      case when extract(quarter from opportunity.createddate__t) = extract(quarter from current_date)  then 1 else 0 end as created_count_this_quarter,
      case when opportunity.closedate__t >= date_trunc('month', current_date) then amount else 0 end as closed_amount_this_month,
      case when extract(quarter from opportunity.closedate__t) = extract(quarter from current_date)  then amount else 0 end as closed_amount_this_quarter,
      case when opportunity.closedate__t >= date_trunc('month', current_date)  then 1 else 0 end as closed_count_this_month,
      case when extract(quarter from opportunity.closedate__t) = extract(quarter from current_date)  then 1 else 0 end as closed_count_this_quarter

  from opportunity
    left join account
      on opportunity.accountid = account.id
    left join salesforce_user as opportunity_owner
      on opportunity.ownerid = opportunity_owner.id
    left join salesforce_user as opportunity_manager
      on opportunity_owner.managerid = opportunity_manager.userroleid
)

select *
from add_fields