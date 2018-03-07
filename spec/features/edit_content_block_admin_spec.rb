RSpec.describe 'Editing content blocks as admin', :js do
  let(:user) { create(:admin) }

  context 'when user wants to change tabs' do
    before do
      sign_in user
      visit '/dashboard'
      click_link 'Settings'
      click_link 'Content Blocks'
    end

    it "gives a confirmation message" do
      expect(page).to have_content('Content Blocks')
      expect(page).to have_content('Announcement')
      click_link 'Marketing Text'
      a = page.driver.browser.switch_to.alert
      expect(a.text).to eq("Are you sure you want to leave this tab?  Any unsaved data will be lost.")
    end

    it "changes tab when user accept the changing tab confirmation" do
      expect(page).to have_selector('#announcement_text', class: 'active')
      expect(page).not_to have_selector('#marketing', class: 'active')
      click_link 'Marketing Text'
      a = page.driver.browser.switch_to.alert
      a.accept
      expect(page).to have_selector('#marketing', class: 'active')
      expect(page).not_to have_selector('#announcement_text', class: 'active')
    end

    it "does not change tab when user cancel the changing tab confirmation" do
      expect(page).to have_selector('#announcement_text', class: 'active')
      expect(page).not_to have_selector('#marketing', class: 'active')
      click_link 'Marketing Text'
      a = page.driver.browser.switch_to.alert
      a.dismiss
      expect(page).not_to have_selector('#marketing', class: 'active')
      expect(page).to have_selector('#announcement_text', class: 'active')
    end
  end
end
