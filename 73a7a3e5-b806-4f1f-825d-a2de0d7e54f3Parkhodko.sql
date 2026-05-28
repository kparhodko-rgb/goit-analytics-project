

with cleaned as ( select user_id, promo_signup_flag, 
        		replace(replace(split_part(trim(signup_datetime), ' ', 1),
        		 '.', '-'), '/', '-') as signup_date
    			from cohort_users_raw cu), -- Чистимо символи в датах реєстрації
 		row_date as (select user_id,promo_signup_flag,
        			case 
            			when length(split_part(signup_date, '-', 3)) = 2 
                	then 
                   	 split_part(signup_date, '-', 1) || '-' ||
                   	 split_part(signup_date, '-', 2) || '-' ||
                    	'20' || split_part(signup_date, '-', 3)
            		else signup_date
        			end as formatted_date
    				from cleaned
    				where signup_date is not null), -- Виправляємо формат року (YY на YYYY)
			cohort_users as (select to_date(formatted_date, 'DD-MM-YYYY') as user_signup, 
								promo_signup_flag,
								user_id
							from row_date), -- Перетворюємо текст на тип DATE
cleaned_event as ( select user_id,event_type,
        			replace(replace(split_part(trim(event_datetime), ' ', 1),
        				'.', '-'), '/', '-') as edt
    			from cohort_events_raw
    			where event_datetime is not null), -- Чистимо дати подій
		row_event_date as (select user_id,event_type,
        				case 
            				when length(split_part(edt, '-', 3)) = 2 
               		 then 
                   		 split_part(edt, '-', 1) || '-' ||
                   		 split_part(edt, '-', 2) || '-' ||
                   		 '20' || split_part(edt, '-', 3)
            			else edt
        					end as formatted_event_date
    					from cleaned_event), -- Виправляємо роки у подіях
				cohort_events as (select to_date(formatted_event_date, 'DD-MM-YYYY') as event_timestamp, 
							user_id, 
							event_type
						from row_event_date
						where event_type is not null 
							and event_type <> 'test_event'), -- Перетворюємо на DATE та прибираємо тести та порожні типи
join_cohort as (select  cu.user_id,  
				cu.promo_signup_flag,
				date_trunc('month', cu.user_signup) as cohort_month,
        		date_trunc('month', ce.event_timestamp) as activity_month,
        		(extract(year from ce.event_timestamp) - extract(year from cu.user_signup)) * 12 +
				(extract(month from ce.event_timestamp) - extract(month from cu.user_signup)) as month_offset
			from cohort_users cu
			inner join cohort_events ce on ce.user_id=cu.user_id) -- Рахуємо місяць життя (offset) та обʼєднуємо таблиці
select 
	promo_signup_flag,
	cohort_month::date,
	month_offset,
	count(distinct user_id) as user_total
from join_cohort
where activity_month between '2025-01-01' and '2025-06-01'
group by promo_signup_flag, cohort_month, month_offset
order by promo_signup_flag, cohort_month, month_offset; -- Фінальна таблиця з кількістю юзерів







  


















