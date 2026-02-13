# Common Operations Rules

## 1. Scope
1. ??洹쒖튃? 湲고쉷, 媛쒕컻, 洹몃옒?? QA ????븷??怨듯넻 ?곸슜?쒕떎.
2. ?꾨줈?앺듃 湲곗? ?붿쭊/?섍꼍? Godot 4.5 + ?꾩옱 ??μ냼 援ъ“瑜??곕Ⅸ??

## 2. Standard Workflow
1. 紐⑤뱺 ?묒뾽? `?붿껌 -> ?묒뾽 -> 寃利?-> 湲곕줉` 4?④퀎瑜??곕Ⅸ??
2. ?④퀎 ?꾨씫 ???꾨즺 泥섎━?섏? ?딅뒗??
3. ???ъ씠??醫낅즺 湲곗?? `?꾩닔 ?곗텧臾??앹꽦 + QA ?ㅻえ???듦낵`??

## 3. Output Paths
1. ?쒖꽦 ?곗텧臾?
`docs/plans`, `docs/plans/data`, `docs/plans/images`, `docs/references`, `docs/graphics`, `docs/reviews`, `docs/qa`
2. ?대젰/蹂닿?:
`docs/archive/ralph_runs`
3. ?꾩떆 ?곗텧臾?
`docs/archive/system_tmp` ?먮뒗 `.tmp`

## 4. Naming Rules
1. 怨꾪쉷 臾몄꽌: `plan_YYYYMMDD_HHMMSS.md`
2. QA 臾몄꽌: `qa_YYYYMMDD_HHMMSS.md`
3. 由щ럭 臾몄꽌: `review_YYYYMMDD_HHMMSS.md`
4. 媛쒕컻 濡쒓렇: `development_log_YYYYMMDD_HHMMSS.md`
5. 由ы룷???뚯씪紐낆? 怨듬갚 ???`_`瑜??ъ슜?쒕떎.

## 5. Archive-First Policy
1. ?????젣 湲덉?, ?곗꽑 ?꾩뭅?대툕 ?대룞 ??寃利앺븳??
2. `docs/archive/ralph_runs` ???대뜑 援ъ“瑜??좎??쒕떎.
3. ?쒖꽦 ?대뜑?먮뒗 理쒖떊 臾몄꽌留??좎??쒕떎.

## 6. Reference and Screenshot Policy
1. 怨꾪쉷 臾몄꽌???몃? ?대?吏 URL 吏곸젒 留곹겕瑜?湲덉??쒕떎.
2. ?대?吏??濡쒖뺄 ?????臾몄꽌?먯꽌 ?곷? 寃쎈줈濡?李몄“?쒕떎.
3. ?ㅽ겕由곗꺑? 諛곗튂 ?⑥쐞 ?대뜑(`batch_0001` ??? ?댁떆 以묐났 ?쒓굅瑜??ъ슜?쒕떎.

## 7. Decision Log Policy
1. 湲고쉷/洹쒖튃 蹂寃쎌? `臾댁뾿`, `??, `?곹뼢 踰붿쐞` 3?붿냼瑜?湲곕줉?쒕떎.
2. 蹂寃?????湲곗?媛믪씠 ?덉쑝硫??섏튂濡??④릿??
3. ?뱀씤?먯? ?뱀씤 ?쒓컖??湲곕줉?쒕떎.

## 8. Build and Run Method
1. Build/smoke verification must run first:
`tools\run_headless_smoke.bat`
2. Stable game run command:
`tools\run_game_stable.bat`
3. Stable run must launch GUI and console together, and enforce windowed mode (`--windowed`).
4. Direct launch fallback (GUI):
`Engine\Godot_v4.5.1-stable_mono_win64\Godot_v4.5.1-stable_mono_win64.exe --path . --rendering-driver opengl3`

## 9. Runtime Startup Error Runbook
1. If startup fails, run checks in this order:
`run_headless_smoke.bat -> run_game_stable.bat -> direct GUI fallback`
2. If this error appears, apply fallback immediately:
`Could not create directory: 'user://logs'`
3. When the `user://logs` error occurs:
- Treat console launch as unstable for that session.
- Use GUI launch path as temporary default.
- Record failure text in QA/review log and verify `user://` write permission and logging path settings before restoring console-first flow.
