#!/bin/bash
# Patch apllying tool template
# v0.1.2
# (c) Copyright 2013. Magento Inc.
#
# DO NOT CHANGE ANY LINE IN THIS FILE.

# 1. Check required system tools
_check_installed_tools() {
    local missed=""

    until [ -z "$1" ]; do
        type -t $1 >/dev/null 2>/dev/null
        if (( $? != 0 )); then
            missed="$missed $1"
        fi
        shift
    done

    echo $missed
}

REQUIRED_UTILS='sed patch'
MISSED_REQUIRED_TOOLS=`_check_installed_tools $REQUIRED_UTILS`
if (( `echo $MISSED_REQUIRED_TOOLS | wc -w` > 0 ));
then
    echo -e "Error! Some required system tools, that are utilized in this sh script, are not installed:\nTool(s) \"$MISSED_REQUIRED_TOOLS\" is(are) missed, please install it(them)."
    exit 1
fi

# 2. Determine bin path for system tools
CAT_BIN=`which cat`
PATCH_BIN=`which patch`
SED_BIN=`which sed`
PWD_BIN=`which pwd`
BASENAME_BIN=`which basename`

BASE_NAME=`$BASENAME_BIN "$0"`

# 3. Help menu
if [ "$1" = "-?" -o "$1" = "-h" -o "$1" = "--help" ]
then
    $CAT_BIN << EOFH
Usage: sh $BASE_NAME [--help] [-R|--revert] [--list]
Apply embedded patch.

-R, --revert    Revert previously applied embedded patch
--list          Show list of applied patches
--help          Show this help message
EOFH
    exit 0
fi

# 4. Get "revert" flag and "list applied patches" flag
REVERT_FLAG=
SHOW_APPLIED_LIST=0
if [ "$1" = "-R" -o "$1" = "--revert" ]
then
    REVERT_FLAG=-R
fi
if [ "$1" = "--list" ]
then
    SHOW_APPLIED_LIST=1
fi

# 5. File pathes
CURRENT_DIR=`$PWD_BIN`/
APP_ETC_DIR=`echo "$CURRENT_DIR""app/etc/"`
APPLIED_PATCHES_LIST_FILE=`echo "$APP_ETC_DIR""applied.patches.list"`

# 6. Show applied patches list if requested
if [ "$SHOW_APPLIED_LIST" -eq 1 ] ; then
    echo -e "Applied/reverted patches list:"
    if [ -e "$APPLIED_PATCHES_LIST_FILE" ]
    then
        if [ ! -r "$APPLIED_PATCHES_LIST_FILE" ]
        then
            echo "ERROR: \"$APPLIED_PATCHES_LIST_FILE\" must be readable so applied patches list can be shown."
            exit 1
        else
            $SED_BIN -n "/SUP-\|SUPEE-/p" $APPLIED_PATCHES_LIST_FILE
        fi
    else
        echo "<empty>"
    fi
    exit 0
fi

# 7. Check applied patches track file and its directory
_check_files() {
    if [ ! -e "$APP_ETC_DIR" ]
    then
        echo "ERROR: \"$APP_ETC_DIR\" must exist for proper tool work."
        exit 1
    fi

    if [ ! -w "$APP_ETC_DIR" ]
    then
        echo "ERROR: \"$APP_ETC_DIR\" must be writeable for proper tool work."
        exit 1
    fi

    if [ -e "$APPLIED_PATCHES_LIST_FILE" ]
    then
        if [ ! -w "$APPLIED_PATCHES_LIST_FILE" ]
        then
            echo "ERROR: \"$APPLIED_PATCHES_LIST_FILE\" must be writeable for proper tool work."
            exit 1
        fi
    fi
}

_check_files

# 8. Apply/revert patch
# Note: there is no need to check files permissions for files to be patched.
# "patch" tool will not modify any file if there is not enough permissions for all files to be modified.
# Get start points for additional information and patch data
SKIP_LINES=$((`$SED_BIN -n "/^__PATCHFILE_FOLLOWS__$/=" "$CURRENT_DIR""$BASE_NAME"` + 1))
ADDITIONAL_INFO_LINE=$(($SKIP_LINES - 3))p

_apply_revert_patch() {
    DRY_RUN_FLAG=
    if [ "$1" = "dry-run" ]
    then
        DRY_RUN_FLAG=" --dry-run"
        echo "Checking if patch can be applied/reverted successfully..."
    fi
    PATCH_APPLY_REVERT_RESULT=`$SED_BIN -e '1,/^__PATCHFILE_FOLLOWS__$/d' "$CURRENT_DIR""$BASE_NAME" | $PATCH_BIN $DRY_RUN_FLAG $REVERT_FLAG -p0`
    PATCH_APPLY_REVERT_STATUS=$?
    if [ $PATCH_APPLY_REVERT_STATUS -eq 1 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully.\n\n$PATCH_APPLY_REVERT_RESULT"
        exit 1
    fi
    if [ $PATCH_APPLY_REVERT_STATUS -eq 2 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully."
        exit 2
    fi
}

REVERTED_PATCH_MARK=
if [ -n "$REVERT_FLAG" ]
then
    REVERTED_PATCH_MARK=" | REVERTED"
fi

_apply_revert_patch dry-run
_apply_revert_patch

# 9. Track patch applying result
echo "Patch was applied/reverted successfully."
ADDITIONAL_INFO=`$SED_BIN -n ""$ADDITIONAL_INFO_LINE"" "$CURRENT_DIR""$BASE_NAME"`
APPLIED_REVERTED_ON_DATE=`date -u +"%F %T UTC"`
APPLIED_REVERTED_PATCH_INFO=`echo -n "$APPLIED_REVERTED_ON_DATE"" | ""$ADDITIONAL_INFO""$REVERTED_PATCH_MARK"`
echo -e "$APPLIED_REVERTED_PATCH_INFO\n$PATCH_APPLY_REVERT_RESULT\n\n" >> "$APPLIED_PATCHES_LIST_FILE"

exit 0


SUPEE-11219_EE_11100 | CE_1.6.0.0 | v1 | 2915941f8d1dc6a093ac75264e5c6d02c6f63989 | Wed Nov 6 19:22:42 2019 +0000 | f021675a7d69d2da309fa0f1129bef9a78c3a7d4..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Enterprise/Banner/controllers/Adminhtml/BannerController.php app/code/core/Enterprise/Banner/controllers/Adminhtml/BannerController.php
index 756cd3e626a..8304da6a8e8 100644
--- app/code/core/Enterprise/Banner/controllers/Adminhtml/BannerController.php
+++ app/code/core/Enterprise/Banner/controllers/Adminhtml/BannerController.php
@@ -210,6 +210,16 @@ class Enterprise_Banner_Adminhtml_BannerController extends Mage_Adminhtml_Contro
         $this->_redirect('*/*/index');
     }
 
+    /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions('delete', 'massDelete');
+        return parent::preDispatch();
+    }
 
     /**
      * Load Banner from request
diff --git app/code/core/Enterprise/Cms/controllers/Adminhtml/Cms/Page/RevisionController.php app/code/core/Enterprise/Cms/controllers/Adminhtml/Cms/Page/RevisionController.php
index e2b5b4b7e7d..75a15f113c1 100644
--- app/code/core/Enterprise/Cms/controllers/Adminhtml/Cms/Page/RevisionController.php
+++ app/code/core/Enterprise/Cms/controllers/Adminhtml/Cms/Page/RevisionController.php
@@ -332,6 +332,7 @@ class Enterprise_Cms_Adminhtml_Cms_Page_RevisionController extends Enterprise_Cm
                     ->setTheme($designChange->getTheme());
             }
 
+            $this->setFlag('', 'preview_rendering', true);
             Mage::helper('cms/page')->renderPageExtended($this);
             Mage::app()->getLocale()->revert();
 
@@ -430,4 +431,26 @@ class Enterprise_Cms_Adminhtml_Cms_Page_RevisionController extends Enterprise_Cm
     {
         $this->_forward('edit');
     }
+
+    /**
+     * Rendering layout
+     *
+     * @param string $output
+     * @return Mage_Core_Controller_Varien_Action
+     */
+    public function renderLayout($output = '')
+    {
+        parent::renderLayout($output);
+
+        if ($this->getFlag('', 'preview_rendering')) {
+            $bodyFiltered = Mage::getSingleton('core/input_filter_maliciousCode')
+                ->linkFilter((string) $this->getResponse()->getBody(), false);
+
+            $this->getResponse()->clearBody();
+            $this->getResponse()->setBody($bodyFiltered);
+            $this->setFlag('', 'preview_rendering', false);
+        }
+
+        return $this;
+    }
 }
diff --git app/code/core/Enterprise/Logging/Block/Adminhtml/Details/Renderer/Diff.php app/code/core/Enterprise/Logging/Block/Adminhtml/Details/Renderer/Diff.php
index e9b721d70dd..a56cb430aff 100644
--- app/code/core/Enterprise/Logging/Block/Adminhtml/Details/Renderer/Diff.php
+++ app/code/core/Enterprise/Logging/Block/Adminhtml/Details/Renderer/Diff.php
@@ -43,7 +43,7 @@ class Enterprise_Logging_Block_Adminhtml_Details_Renderer_Diff
         $columnData = $row->getData($this->getColumn()->getIndex());
         $specialFlag = false;
         try {
-            $dataArray = unserialize($columnData);
+            $dataArray = $this->helper('core/string')->unserialize($columnData);
             if (is_bool($dataArray)) {
                 $html = $dataArray ? 'true' : 'false';
             }
diff --git app/code/core/Enterprise/Pci/Model/Encryption.php app/code/core/Enterprise/Pci/Model/Encryption.php
index 75438f5e52d..e8066f00614 100644
--- app/code/core/Enterprise/Pci/Model/Encryption.php
+++ app/code/core/Enterprise/Pci/Model/Encryption.php
@@ -31,9 +31,14 @@
  */
 class Enterprise_Pci_Model_Encryption extends Mage_Core_Model_Encryption
 {
-    const HASH_VERSION_MD5    = 0;
-    const HASH_VERSION_SHA256 = 1;
-    const HASH_VERSION_LATEST = 1;
+    const HASH_VERSION_MD5     = 0;
+    const HASH_VERSION_SHA256  = 1;
+    const HASH_VERSION_SHA512  = 2;
+
+    /**
+     * Encryption method bcrypt
+     */
+    const HASH_VERSION_LATEST = 3;
 
     const CIPHER_BLOWFISH     = 0;
     const CIPHER_RIJNDAEL_128 = 1;
@@ -84,7 +89,9 @@ class Enterprise_Pci_Model_Encryption extends Mage_Core_Model_Encryption
      */
     public function validateHash($password, $hash)
     {
-        return $this->validateHashByVersion($password, $hash, self::HASH_VERSION_SHA256)
+        return $this->validateHashByVersion($password, $hash, self::HASH_VERSION_LATEST)
+            || $this->validateHashByVersion($password, $hash, self::HASH_VERSION_SHA512)
+            || $this->validateHashByVersion($password, $hash, self::HASH_VERSION_SHA256)
             || $this->validateHashByVersion($password, $hash, self::HASH_VERSION_MD5);
     }
 
@@ -95,14 +102,29 @@ class Enterprise_Pci_Model_Encryption extends Mage_Core_Model_Encryption
      * @param int $version
      * @return string
      */
-    public function hash($data, $version = self::HASH_VERSION_LATEST)
+    public function hash($data, $version = self::HASH_VERSION_SHA256)
     {
         if (self::HASH_VERSION_MD5 === $version) {
             return md5($data);
+        } elseif (self::HASH_VERSION_SHA512 === $version) {
+            return hash('sha512', $data);
+        } elseif (self::HASH_VERSION_LATEST === $version && $version === $this->_helper->getVersionHash($this)) {
+            return password_hash($data, PASSWORD_DEFAULT);
         }
         return hash('sha256', $data);
     }
 
+    /**
+     * Password hash
+     *
+     * @param string $data
+     * @return bool|string
+     */
+    public function passwordHash($data)
+    {
+        return password_hash($data, PASSWORD_DEFAULT);
+    }
+
     /**
      * Validate hash by specified version
      *
@@ -113,6 +135,9 @@ class Enterprise_Pci_Model_Encryption extends Mage_Core_Model_Encryption
      */
     public function validateHashByVersion($password, $hash, $version = self::HASH_VERSION_LATEST)
     {
+        if ($version == self::HASH_VERSION_LATEST && $version == $this->_helper->getVersionHash($this)) {
+            return password_verify($password, $hash);
+        }
         // look for salt
         $hashArr = explode(':', $hash, 2);
         if (1 === count($hashArr)) {
diff --git app/code/core/Enterprise/Pci/Model/Observer.php app/code/core/Enterprise/Pci/Model/Observer.php
index d8e2fc9f31c..738c688d2d8 100644
--- app/code/core/Enterprise/Pci/Model/Observer.php
+++ app/code/core/Enterprise/Pci/Model/Observer.php
@@ -109,7 +109,11 @@ class Enterprise_Pci_Model_Observer
         }
 
         // upgrade admin password
-        if (!Mage::helper('core')->getEncryptor()->validateHashByVersion($password, $user->getPassword())) {
+        if (!Mage::helper('core')->getEncryptor()->validateHashByVersion(
+            $password,
+            $user->getPassword(),
+            Mage::helper('core')->getVersionHash(Mage::helper('core')->getEncryptor()))
+        ) {
             Mage::getModel('admin/user')->load($user->getId())
                 ->setNewPassword($password)->setForceNewPassword(true)
                 ->save();
@@ -125,7 +129,9 @@ class Enterprise_Pci_Model_Observer
     {
         $apiKey = $observer->getEvent()->getApiKey();
         $model  = $observer->getEvent()->getModel();
-        if (!Mage::helper('core')->getEncryptor()->validateHashByVersion($apiKey, $model->getApiKey())) {
+        $coreHelper = Mage::helper('core');
+        $currentVersionHash = $coreHelper->getVersionHash($coreHelper->getEncryptor());
+        if (!Mage::helper('core')->getEncryptor()->validateHashByVersion($apiKey, $model->getApiKey(), $currentVersionHash)) {
             Mage::getModel('acl/user')->load($model->getId())->setNewApiKey($apiKey)->save();
         }
     }
@@ -139,7 +145,27 @@ class Enterprise_Pci_Model_Observer
     {
         $password = $observer->getEvent()->getPassword();
         $model    = $observer->getEvent()->getModel();
-        if (!Mage::helper('core')->getEncryptor()->validateHashByVersion($password, $model->getPassword())) {
+
+        /** @var Mage_Core_Helper_Data $helper */
+        $helper = Mage::helper('core');
+
+        $encryptor = $helper->getEncryptor();
+
+        $hashVersionArray = [
+            Enterprise_Pci_Model_Encryption::HASH_VERSION_MD5,
+            Enterprise_Pci_Model_Encryption::HASH_VERSION_SHA256,
+            Enterprise_Pci_Model_Encryption::HASH_VERSION_SHA512,
+            Enterprise_Pci_Model_Encryption::HASH_VERSION_LATEST,
+        ];
+        $latestVersionHash = $helper->getVersionHash($encryptor);
+        $currentVersionHash = null;
+        foreach ($hashVersionArray as $hashVersion) {
+            if ($encryptor->validateHashByVersion($password, $model->getPasswordHash(), $hashVersion)) {
+                $currentVersionHash = $hashVersion;
+                break;
+            }
+        }
+        if ($latestVersionHash !== $currentVersionHash) {
             $model->changePassword($password, false);
         }
     }
diff --git app/code/core/Enterprise/Pci/etc/config.xml app/code/core/Enterprise/Pci/etc/config.xml
index fd5338ed382..86b38d3cf94 100644
--- app/code/core/Enterprise/Pci/etc/config.xml
+++ app/code/core/Enterprise/Pci/etc/config.xml
@@ -28,7 +28,7 @@
 <config>
     <modules>
         <Enterprise_Pci>
-            <version>1.11.0.0</version>
+            <version>1.11.0.2</version>
         </Enterprise_Pci>
     </modules>
     <global>
diff --git app/code/core/Enterprise/Pci/sql/enterprise_pci_setup/mysql4-upgrade-1.11.0.0-1.11.0.1.php app/code/core/Enterprise/Pci/sql/enterprise_pci_setup/mysql4-upgrade-1.11.0.0-1.11.0.1.php
new file mode 100644
index 00000000000..5efe30c45eb
--- /dev/null
+++ app/code/core/Enterprise/Pci/sql/enterprise_pci_setup/mysql4-upgrade-1.11.0.0-1.11.0.1.php
@@ -0,0 +1,41 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage
+ * @copyright Copyright (c) 2006-2019 Magento, Inc. (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+/* @var $installer Enterprise_Pci_Model_Resource_Setup */
+$installer = $this;
+$installer->startSetup();
+//Increase password field length
+$installer->getConnection()->changeColumn(
+    $installer->getTable('admin/user'),
+    'password',
+    'password',
+    array(
+        'type' => Varien_Db_Ddl_Table::TYPE_TEXT,
+        'length' => 255,
+        'comment' => 'User Password',
+    )
+);
+$installer->endSetup();
diff --git app/code/core/Enterprise/Pci/sql/enterprise_pci_setup/mysql4-upgrade-1.11.0.1-1.11.0.2.php app/code/core/Enterprise/Pci/sql/enterprise_pci_setup/mysql4-upgrade-1.11.0.1-1.11.0.2.php
new file mode 100644
index 00000000000..c8e590b73ef
--- /dev/null
+++ app/code/core/Enterprise/Pci/sql/enterprise_pci_setup/mysql4-upgrade-1.11.0.1-1.11.0.2.php
@@ -0,0 +1,41 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage
+ * @copyright Copyright (c) 2006-2019 Magento, Inc. (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+/* @var $installer Enterprise_Pci_Model_Resource_Setup */
+$installer = $this;
+$installer->startSetup();
+
+$installer->getConnection()->changeColumn(
+    $installer->getTable('api/user'),
+    'api_key',
+    'api_key',
+    array(
+        'type' => Varien_Db_Ddl_Table::TYPE_TEXT,
+        'length' => 255,
+        'comment' => 'Api key',
+    )
+);
+$installer->endSetup();
diff --git app/code/core/Enterprise/Reminder/controllers/Adminhtml/ReminderController.php app/code/core/Enterprise/Reminder/controllers/Adminhtml/ReminderController.php
index dede2f144ed..d356891441f 100644
--- app/code/core/Enterprise/Reminder/controllers/Adminhtml/ReminderController.php
+++ app/code/core/Enterprise/Reminder/controllers/Adminhtml/ReminderController.php
@@ -256,6 +256,17 @@ class Enterprise_Reminder_Adminhtml_ReminderController extends Mage_Adminhtml_Co
         }
     }
 
+    /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions('delete');
+        return parent::preDispatch();
+    }
+
     /**
      * Check the permission to run it
      *
diff --git app/code/core/Enterprise/Rma/Block/Adminhtml/Rma/Edit.php app/code/core/Enterprise/Rma/Block/Adminhtml/Rma/Edit.php
index eb037ec9704..d8f3221b08d 100644
--- app/code/core/Enterprise/Rma/Block/Adminhtml/Rma/Edit.php
+++ app/code/core/Enterprise/Rma/Block/Adminhtml/Rma/Edit.php
@@ -173,7 +173,7 @@ class Enterprise_Rma_Block_Adminhtml_Rma_Edit extends Mage_Adminhtml_Block_Widge
      */
     public function getCloseUrl()
     {
-        return $this->getUrl('*/*/close', array(
+        return $this->getUrlSecure('*/*/close', array(
             'entity_id' => $this->getRma()->getId()
         ));
     }
diff --git app/code/core/Enterprise/Rma/controllers/Adminhtml/RmaController.php app/code/core/Enterprise/Rma/controllers/Adminhtml/RmaController.php
index 938d8efda03..6f6de9e847d 100644
--- app/code/core/Enterprise/Rma/controllers/Adminhtml/RmaController.php
+++ app/code/core/Enterprise/Rma/controllers/Adminhtml/RmaController.php
@@ -1314,4 +1314,15 @@ class Enterprise_Rma_Adminhtml_RmaController extends Mage_Adminhtml_Controller_A
         }
         $this->getResponse()->setBody($response);
     }
+
+    /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions('close');
+        return parent::preDispatch();
+    }
 }
diff --git app/code/core/Enterprise/Staging/Block/Adminhtml/Staging/Edit/Tabs/Website.php app/code/core/Enterprise/Staging/Block/Adminhtml/Staging/Edit/Tabs/Website.php
index 5cb06133248..9092e9f358e 100644
--- app/code/core/Enterprise/Staging/Block/Adminhtml/Staging/Edit/Tabs/Website.php
+++ app/code/core/Enterprise/Staging/Block/Adminhtml/Staging/Edit/Tabs/Website.php
@@ -196,13 +196,17 @@ class Enterprise_Staging_Block_Adminhtml_Staging_Edit_Tabs_Website extends Mage_
                 )
             );
 
+            $minPasswordLength = Mage::getModel('customer/customer')->getMinPasswordLength();
             $fieldset->addField('staging_website_master_password_'.$_id, 'text',
                 array(
                     'label'    => Mage::helper('enterprise_staging')->__('HTTP Password'),
-                    'class'    => 'input-text validate-password',
+                    'class'    => 'input-text validate-password min-pass-length-' . $minPasswordLength,
                     'name'     => "websites[{$_id}][master_password]",
                     'required' => true,
-                    'value'    => $stagingWebsite ? Mage::helper('core')->decrypt($stagingWebsite->getMasterPassword()) : ''
+                    'value'    => $stagingWebsite ? Mage::helper('core')->decrypt($stagingWebsite->getMasterPassword())
+                        : '',
+                    'note' => Mage::helper('adminhtml')
+                        ->__('Password must be at least of %d characters.', $minPasswordLength),
                 )
             );
 
diff --git app/code/core/Enterprise/Staging/Model/Resource/Adapter/Website.php app/code/core/Enterprise/Staging/Model/Resource/Adapter/Website.php
old mode 100755
new mode 100644
index f21ada79a12..6613e05897d
--- app/code/core/Enterprise/Staging/Model/Resource/Adapter/Website.php
+++ app/code/core/Enterprise/Staging/Model/Resource/Adapter/Website.php
@@ -64,8 +64,12 @@ class Enterprise_Staging_Model_Resource_Adapter_Website extends Enterprise_Stagi
             $stagingWebsite->setData('master_login', $website->getMasterLogin());
             $password = trim($website->getMasterPassword());
             if ($password) {
-                 if(Mage::helper('core/string')->strlen($password)<6){
-                    throw new Enterprise_Staging_Exception(Mage::helper('enterprise_staging')->__('The password must have at least 6 characters. Leading or trailing spaces will be ignored.'));
+                $minPasswordLength = Mage::getModel('customer/customer')->getMinPasswordLength();
+                if (Mage::helper('core/string')->strlen($password) < $minPasswordLength) {
+                    throw new Enterprise_Staging_Exception(Mage::helper('enterprise_staging')->__(
+                        'The password must have at least %d characters. Leading or trailing spaces will be ignored.',
+                        $minPasswordLength
+                    ));
                 }
                 $stagingWebsite->setData('master_password' , Mage::helper('core')->encrypt($password));
             }
@@ -136,8 +140,12 @@ class Enterprise_Staging_Model_Resource_Adapter_Website extends Enterprise_Stagi
             $stagingWebsite->setData('master_login', $website->getMasterLogin());
             $password = trim($website->getMasterPassword());
             if ($password) {
-                 if(Mage::helper('core/string')->strlen($password)<6){
-                    throw new Enterprise_Staging_Exception(Mage::helper('enterprise_staging')->__('The password must have at least 6 characters. Leading or trailing spaces will be ignored.'));
+                $minPasswordLength = Mage::getModel('customer/customer')->getMinPasswordLength();
+                if (Mage::helper('core/string')->strlen($password) < $minPasswordLength) {
+                    throw new Enterprise_Staging_Exception(Mage::helper('enterprise_staging')->__(
+                        'The password must have at least %d characters. Leading or trailing spaces will be ignored.',
+                        $minPasswordLength
+                    ));
                 }
                 $stagingWebsite->setData('master_password' , Mage::helper('core')->encrypt($password));
             }
diff --git app/code/core/Mage/Admin/Model/User.php app/code/core/Mage/Admin/Model/User.php
index 861bdb5e3e7..be28bf6edce 100644
--- app/code/core/Mage/Admin/Model/User.php
+++ app/code/core/Mage/Admin/Model/User.php
@@ -63,7 +63,27 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
     const XML_PATH_FORGOT_EMAIL_TEMPLATE    = 'admin/emails/forgot_email_template';
     const XML_PATH_FORGOT_EMAIL_IDENTITY    = 'admin/emails/forgot_email_identity';
     const XML_PATH_STARTUP_PAGE             = 'admin/startup/page';
-    const MIN_PASSWORD_LENGTH = 7;
+
+    /**
+     * Minimum length of admin password
+     * @deprecated Use getMinAdminPasswordLength() method instead
+     */
+    const MIN_PASSWORD_LENGTH = 14;
+
+    /**
+     * Configuration path for minimum length of admin password
+     */
+    const XML_PATH_MIN_ADMIN_PASSWORD_LENGTH = 'admin/security/min_admin_password_length';
+
+    /**
+     * Length of salt
+     */
+    const HASH_SALT_LENGTH = 32;
+
+    /**
+     * Empty hash salt
+     */
+    const HASH_SALT_EMPTY = null;
 
     protected $_eventPrefix = 'admin_user';
 
@@ -346,7 +366,7 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
 
     protected function _getEncodedPassword($pwd)
     {
-        return Mage::helper('core')->getHash($pwd, 2);
+        return Mage::helper('core')->getHashPassword($pwd, self::HASH_SALT_LENGTH);
     }
 
     /**
@@ -445,15 +465,23 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
         }
 
         if ($this->hasNewPassword()) {
-            if (Mage::helper('core/string')->strlen($this->getNewPassword()) < self::MIN_PASSWORD_LENGTH) {
-                $errors[] = Mage::helper('adminhtml')->__('Password must be at least of %d characters.', self::MIN_PASSWORD_LENGTH);
+            $password = $this->getNewPassword();
+        } elseif ($this->hasPassword()) {
+            $password = $this->getPassword();
+        }
+        if (isset($password)) {
+            $minAdminPasswordLength = $this->getMinAdminPasswordLength();
+            if (Mage::helper('core/string')->strlen($password) < $minAdminPasswordLength) {
+                $errors[] = Mage::helper('adminhtml')
+                    ->__('Password must be at least of %d characters.', $minAdminPasswordLength);
             }
 
-            if (!preg_match('/[a-z]/iu', $this->getNewPassword()) || !preg_match('/[0-9]/u', $this->getNewPassword())) {
-                $errors[] = Mage::helper('adminhtml')->__('Password must include both numeric and alphabetic characters.');
+            if (!preg_match('/[a-z]/iu', $password) || !preg_match('/[0-9]/u', $password)) {
+                $errors[] = Mage::helper('adminhtml')
+                    ->__('Password must include both numeric and alphabetic characters.');
             }
 
-            if ($this->hasPasswordConfirmation() && $this->getNewPassword() != $this->getPasswordConfirmation()) {
+            if ($this->hasPasswordConfirmation() && $password != $this->getPasswordConfirmation()) {
                 $errors[] = Mage::helper('adminhtml')->__('Password confirmation must be same as password.');
             }
 
@@ -521,4 +549,16 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
         $emails = str_replace(' ', '', Mage::getStoreConfig(self::XML_PATH_ADDITIONAL_EMAILS));
         return explode(',', $emails);
     }
+
+    /**
+     * Retrieve minimum length of admin password
+     *
+     * @return int
+     */
+    public function getMinAdminPasswordLength()
+    {
+        $minLength = (int)Mage::getStoreConfig(self::XML_PATH_MIN_ADMIN_PASSWORD_LENGTH);
+        $absoluteMinLength = Mage_Core_Model_App::ABSOLUTE_MIN_PASSWORD_LENGTH;
+        return ($minLength < $absoluteMinLength) ? $absoluteMinLength : $minLength;
+    }
 }
diff --git app/code/core/Mage/Admin/etc/config.xml app/code/core/Mage/Admin/etc/config.xml
index 8d9097894b7..0df0190e94b 100644
--- app/code/core/Mage/Admin/etc/config.xml
+++ app/code/core/Mage/Admin/etc/config.xml
@@ -28,7 +28,7 @@
 <config>
     <modules>
         <Mage_Admin>
-            <version>1.6.0.0.1.2</version>
+            <version>1.6.0.0.1.3</version>
         </Mage_Admin>
     </modules>
     <global>
diff --git app/code/core/Mage/Admin/sql/admin_setup/upgrade-1.6.0.0.1.2-1.6.0.0.1.3.php app/code/core/Mage/Admin/sql/admin_setup/upgrade-1.6.0.0.1.2-1.6.0.0.1.3.php
new file mode 100644
index 00000000000..7ce088e0227
--- /dev/null
+++ app/code/core/Mage/Admin/sql/admin_setup/upgrade-1.6.0.0.1.2-1.6.0.0.1.3.php
@@ -0,0 +1,43 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage
+ * @copyright Copyright (c) 2006-2019 Magento, Inc. (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+/** @var $installer Mage_Core_Model_Resource_Setup */
+$installer = $this;
+$installer->startSetup();
+
+//Increase password field length
+$installer->getConnection()->changeColumn(
+    $installer->getTable('admin/user'),
+    'password',
+    'password',
+    array(
+        'type' => Varien_Db_Ddl_Table::TYPE_TEXT,
+        'length' => 255,
+        'comment' => 'User Password',
+    )
+);
+
+$installer->endSetup();
diff --git app/code/core/Mage/Adminhtml/Block/Api/User/Edit/Tab/Main.php app/code/core/Mage/Adminhtml/Block/Api/User/Edit/Tab/Main.php
index 6f40e04d9f9..5a9f10194ab 100644
--- app/code/core/Mage/Adminhtml/Block/Api/User/Edit/Tab/Main.php
+++ app/code/core/Mage/Adminhtml/Block/Api/User/Edit/Tab/Main.php
@@ -88,13 +88,16 @@ class Mage_Adminhtml_Block_Api_User_Edit_Tab_Main extends Mage_Adminhtml_Block_W
             'required' => true,
         ));
 
+        $minPasswordLength = Mage::getModel('customer/customer')->getMinPasswordLength();
         if ($model->getUserId()) {
             $fieldset->addField('password', 'password', array(
                 'name'  => 'new_api_key',
                 'label' => Mage::helper('adminhtml')->__('New API Key'),
                 'id'    => 'new_pass',
                 'title' => Mage::helper('adminhtml')->__('New API Key'),
-                'class' => 'input-text validate-password',
+                'class' => 'input-text validate-password min-pass-length-' . $minPasswordLength,
+                'note' => Mage::helper('adminhtml')
+                    ->__('API Key must be at least of %d characters.', $minPasswordLength),
             ));
 
             $fieldset->addField('confirmation', 'password', array(
@@ -105,15 +108,17 @@ class Mage_Adminhtml_Block_Api_User_Edit_Tab_Main extends Mage_Adminhtml_Block_W
             ));
         }
         else {
-           $fieldset->addField('password', 'password', array(
+            $fieldset->addField('password', 'password', array(
                 'name'  => 'api_key',
                 'label' => Mage::helper('adminhtml')->__('API Key'),
                 'id'    => 'customer_pass',
                 'title' => Mage::helper('adminhtml')->__('API Key'),
-                'class' => 'input-text required-entry validate-password',
+                'class' => 'input-text required-entry validate-password min-pass-length-' . $minPasswordLength,
                 'required' => true,
+                'note' => Mage::helper('adminhtml')
+                    ->__('API Key must be at least of %d characters.', $minPasswordLength),
             ));
-           $fieldset->addField('confirmation', 'password', array(
+            $fieldset->addField('confirmation', 'password', array(
                 'name'  => 'api_key_confirmation',
                 'label' => Mage::helper('adminhtml')->__('API Key Confirmation'),
                 'id'    => 'confirmation',
diff --git app/code/core/Mage/Adminhtml/Block/Catalog/Product/Attribute/Set/Main.php app/code/core/Mage/Adminhtml/Block/Catalog/Product/Attribute/Set/Main.php
index fbc86536138..cef331ee0ad 100644
--- app/code/core/Mage/Adminhtml/Block/Catalog/Product/Attribute/Set/Main.php
+++ app/code/core/Mage/Adminhtml/Block/Catalog/Product/Attribute/Set/Main.php
@@ -93,10 +93,13 @@ class Mage_Adminhtml_Block_Catalog_Product_Attribute_Set_Main extends Mage_Admin
                 'class'     => 'save'
         )));
 
+        $deleteConfirmMessage = $this->jsQuoteEscape(Mage::helper('catalog')
+            ->__('All products of this set will be deleted! Are you sure you want to delete this attribute set?'));
+        $deleteUrl = $this->getUrlSecure('*/*/delete', array('id' => $setId));
         $this->setChild('delete_button',
             $this->getLayout()->createBlock('adminhtml/widget_button')->setData(array(
                 'label'     => Mage::helper('catalog')->__('Delete Attribute Set'),
-                'onclick'   => 'deleteConfirm(\''. $this->jsQuoteEscape(Mage::helper('catalog')->__('All products of this set will be deleted! Are you sure you want to delete this attribute set?')) . '\', \'' . $this->getUrl('*/*/delete', array('id' => $setId)) . '\')',
+                'onclick'   => 'deleteConfirm(\'' . $deleteConfirmMessage . '\', \'' . $deleteUrl . '\')',
                 'class'     => 'delete'
         )));
 
diff --git app/code/core/Mage/Adminhtml/Block/Customer/Edit/Renderer/Newpass.php app/code/core/Mage/Adminhtml/Block/Customer/Edit/Renderer/Newpass.php
index 4ad3ad29c8b..7241c383c84 100644
--- app/code/core/Mage/Adminhtml/Block/Customer/Edit/Renderer/Newpass.php
+++ app/code/core/Mage/Adminhtml/Block/Customer/Edit/Renderer/Newpass.php
@@ -38,7 +38,11 @@ class Mage_Adminhtml_Block_Customer_Edit_Renderer_Newpass extends Mage_Adminhtml
     {
         $html = '<tr>';
         $html.= '<td class="label">'.$element->getLabelHtml().'</td>';
-        $html.= '<td class="value">'.$element->getElementHtml().'</td>';
+        $html .= '<td class="value">' . $element->getElementHtml();
+        if ($element->getNote()) {
+            $html .= '<p class="note"><span>' . $element->getNote() . '</span></p>';
+        }
+        $html .= '</td>';
         $html.= '</tr>'."\n";
         $html.= '<tr>';
         $html.= '<td class="label"><label>&nbsp;</label></td>';
diff --git app/code/core/Mage/Adminhtml/Block/Customer/Edit/Tab/Account.php app/code/core/Mage/Adminhtml/Block/Customer/Edit/Tab/Account.php
index 3a23085a0fe..fecb0194556 100644
--- app/code/core/Mage/Adminhtml/Block/Customer/Edit/Tab/Account.php
+++ app/code/core/Mage/Adminhtml/Block/Customer/Edit/Tab/Account.php
@@ -63,8 +63,12 @@ class Mage_Adminhtml_Block_Customer_Edit_Tab_Account extends Mage_Adminhtml_Bloc
         $this->_setFieldset($attributes, $fieldset);
 
         if ($customer->getId()) {
-            $form->getElement('website_id')->setDisabled('disabled');
-            $form->getElement('created_in')->setDisabled('disabled');
+            if ($element = $form->getElement('website_id')) {
+                $element->setDisabled('disabled');
+            }
+            if ($element = $form->getElement('created_in')) {
+                $element->setDisabled('disabled');
+            }
         } else {
             $fieldset->removeField('created_in');
         }
@@ -117,6 +121,7 @@ class Mage_Adminhtml_Block_Customer_Edit_Tab_Account extends Mage_Adminhtml_Bloc
             }
         }
 
+        $minPasswordLength = Mage::getModel('customer/customer')->getMinPasswordLength();
         if ($customer->getId()) {
             if (!$customer->isReadonly()) {
                 // add password management fieldset
@@ -129,7 +134,9 @@ class Mage_Adminhtml_Block_Customer_Edit_Tab_Account extends Mage_Adminhtml_Bloc
                     array(
                         'label' => Mage::helper('customer')->__('New Password'),
                         'name'  => 'new_password',
-                        'class' => 'validate-new-password'
+                        'class' => 'validate-new-password min-pass-length-' . $minPasswordLength,
+                        'note' => Mage::helper('adminhtml')
+                            ->__('Password must be at least of %d characters.', $minPasswordLength),
                     )
                 );
                 $field->setRenderer($this->getLayout()->createBlock('adminhtml/customer_edit_renderer_newpass'));
@@ -166,9 +173,11 @@ class Mage_Adminhtml_Block_Customer_Edit_Tab_Account extends Mage_Adminhtml_Bloc
             $field = $newFieldset->addField('password', 'text',
                 array(
                     'label' => Mage::helper('customer')->__('Password'),
-                    'class' => 'input-text required-entry validate-password',
+                    'class' => 'input-text required-entry validate-password min-pass-length-' . $minPasswordLength,
                     'name'  => 'password',
-                    'required' => true
+                    'required' => true,
+                    'note' => Mage::helper('adminhtml')
+                        ->__('Password must be at least of %d characters.', $minPasswordLength),
                 )
             );
             $field->setRenderer($this->getLayout()->createBlock('adminhtml/customer_edit_renderer_newpass'));
diff --git app/code/core/Mage/Adminhtml/Block/Newsletter/Queue/Preview.php app/code/core/Mage/Adminhtml/Block/Newsletter/Queue/Preview.php
index 416e1ba96f8..83d71d608b0 100644
--- app/code/core/Mage/Adminhtml/Block/Newsletter/Queue/Preview.php
+++ app/code/core/Mage/Adminhtml/Block/Newsletter/Queue/Preview.php
@@ -76,6 +76,9 @@ class Mage_Adminhtml_Block_Newsletter_Queue_Preview extends Mage_Adminhtml_Block
             $templateProcessed = "<pre>" . htmlspecialchars($templateProcessed) . "</pre>";
         }
 
+        $templateProcessed = Mage::getSingleton('core/input_filter_maliciousCode')
+            ->linkFilter($templateProcessed);
+
         Varien_Profiler::stop("newsletter_queue_proccessing");
 
         return $templateProcessed;
diff --git app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Edit.php app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Edit.php
index 41bb63defa6..c6aaf5328ec 100644
--- app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Edit.php
+++ app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Edit.php
@@ -315,7 +315,7 @@ class Mage_Adminhtml_Block_Newsletter_Template_Edit extends Mage_Adminhtml_Block
      */
     public function getDeleteUrl()
     {
-        return $this->getUrl('*/*/delete', array('id' => $this->getRequest()->getParam('id')));
+        return $this->getUrlSecure('*/*/delete', array('id' => $this->getRequest()->getParam('id')));
     }
 
     /**
diff --git app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Preview.php app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Preview.php
index bfcd76e806e..8fce90cf886 100644
--- app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Preview.php
+++ app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Preview.php
@@ -74,6 +74,9 @@ class Mage_Adminhtml_Block_Newsletter_Template_Preview extends Mage_Adminhtml_Bl
             $templateProcessed = "<pre>" . htmlspecialchars($templateProcessed) . "</pre>";
         }
 
+        $templateProcessed = Mage::getSingleton('core/input_filter_maliciousCode')
+            ->linkFilter($templateProcessed);
+
         Varien_Profiler::stop("newsletter_template_proccessing");
 
         return $templateProcessed;
diff --git app/code/core/Mage/Adminhtml/Block/Permissions/Tab/Useredit.php app/code/core/Mage/Adminhtml/Block/Permissions/Tab/Useredit.php
index d46e8df5768..3a076a1c4ee 100644
--- app/code/core/Mage/Adminhtml/Block/Permissions/Tab/Useredit.php
+++ app/code/core/Mage/Adminhtml/Block/Permissions/Tab/Useredit.php
@@ -85,6 +85,7 @@ class Mage_Adminhtml_Block_Permissions_Tab_Useredit extends Mage_Adminhtml_Block
             )
         );
 
+        $minPasswordLength = Mage::getModel('customer/customer')->getMinPasswordLength();
         if ($user->getUserId()) {
             $fieldset->addField('password', 'password',
                 array(
@@ -92,7 +93,9 @@ class Mage_Adminhtml_Block_Permissions_Tab_Useredit extends Mage_Adminhtml_Block
                     'label' => Mage::helper('adminhtml')->__('New Password'),
                     'id'    => 'new_pass',
                     'title' => Mage::helper('adminhtml')->__('New Password'),
-                    'class' => 'input-text validate-password',
+                    'class' => 'input-text validate-password min-pass-length-' . $minPasswordLength,
+                    'note' => Mage::helper('adminhtml')
+                        ->__('Password must be at least of %d characters.', $minPasswordLength),
                 )
             );
 
@@ -112,8 +115,10 @@ class Mage_Adminhtml_Block_Permissions_Tab_Useredit extends Mage_Adminhtml_Block
                     'label' => Mage::helper('adminhtml')->__('Password'),
                     'id'    => 'customer_pass',
                     'title' => Mage::helper('adminhtml')->__('Password'),
-                    'class' => 'input-text required-entry validate-password',
+                    'class' => 'input-text required-entry validate-password min-pass-length-' . $minPasswordLength,
                     'required' => true,
+                    'note' => Mage::helper('adminhtml')
+                        ->__('Password must be at least of %d characters.', $minPasswordLength),
                 )
             );
            $fieldset->addField('confirmation', 'password',
diff --git app/code/core/Mage/Adminhtml/Block/Permissions/User/Edit/Tab/Main.php app/code/core/Mage/Adminhtml/Block/Permissions/User/Edit/Tab/Main.php
index bd471b3511f..dd65d0c5ef1 100644
--- app/code/core/Mage/Adminhtml/Block/Permissions/User/Edit/Tab/Main.php
+++ app/code/core/Mage/Adminhtml/Block/Permissions/User/Edit/Tab/Main.php
@@ -88,13 +88,16 @@ class Mage_Adminhtml_Block_Permissions_User_Edit_Tab_Main extends Mage_Adminhtml
             'required' => true,
         ));
 
+        $minAdminPasswordLength = Mage::getModel('admin/user')->getMinAdminPasswordLength();
         if ($model->getUserId()) {
             $fieldset->addField('password', 'password', array(
                 'name'  => 'new_password',
                 'label' => Mage::helper('adminhtml')->__('New Password'),
                 'id'    => 'new_pass',
                 'title' => Mage::helper('adminhtml')->__('New Password'),
-                'class' => 'input-text validate-admin-password',
+                'class' => 'input-text validate-admin-password min-admin-pass-length-' . $minAdminPasswordLength,
+                'note' => Mage::helper('adminhtml')
+                    ->__('Password must be at least of %d characters.', $minAdminPasswordLength),
             ));
 
             $fieldset->addField('confirmation', 'password', array(
@@ -105,15 +108,18 @@ class Mage_Adminhtml_Block_Permissions_User_Edit_Tab_Main extends Mage_Adminhtml
             ));
         }
         else {
-           $fieldset->addField('password', 'password', array(
+            $fieldset->addField('password', 'password', array(
                 'name'  => 'password',
                 'label' => Mage::helper('adminhtml')->__('Password'),
                 'id'    => 'customer_pass',
                 'title' => Mage::helper('adminhtml')->__('Password'),
-                'class' => 'input-text required-entry validate-admin-password',
+                'class' => 'input-text required-entry validate-admin-password min-admin-pass-length-'
+                    . $minAdminPasswordLength,
                 'required' => true,
+                'note' => Mage::helper('adminhtml')
+                    ->__('Password must be at least of %d characters.', $minAdminPasswordLength),
             ));
-           $fieldset->addField('confirmation', 'password', array(
+            $fieldset->addField('confirmation', 'password', array(
                 'name'  => 'password_confirmation',
                 'label' => Mage::helper('adminhtml')->__('Password Confirmation'),
                 'id'    => 'confirmation',
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/View.php app/code/core/Mage/Adminhtml/Block/Sales/Order/View.php
index 96036e70bd5..4cb7253a2ac 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/View.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/View.php
@@ -218,7 +218,7 @@ class Mage_Adminhtml_Block_Sales_Order_View extends Mage_Adminhtml_Block_Widget_
 
     public function getCancelUrl()
     {
-        return $this->getUrl('*/*/cancel');
+        return $this->getUrlSecure('*/*/cancel');
     }
 
     public function getInvoiceUrl()
diff --git app/code/core/Mage/Adminhtml/Block/System/Account/Edit/Form.php app/code/core/Mage/Adminhtml/Block/System/Account/Edit/Form.php
index 6b714ec124e..75a3a92958d 100644
--- app/code/core/Mage/Adminhtml/Block/System/Account/Edit/Form.php
+++ app/code/core/Mage/Adminhtml/Block/System/Account/Edit/Form.php
@@ -82,11 +82,14 @@ class Mage_Adminhtml_Block_System_Account_Edit_Form extends Mage_Adminhtml_Block
             )
         );
 
+        $minAdminPasswordLength = Mage::getModel('admin/user')->getMinAdminPasswordLength();
         $fieldset->addField('password', 'password', array(
                 'name'  => 'new_password',
                 'label' => Mage::helper('adminhtml')->__('New Password'),
                 'title' => Mage::helper('adminhtml')->__('New Password'),
-                'class' => 'input-text validate-admin-password',
+                'class' => 'input-text validate-admin-password min-admin-pass-length-' . $minAdminPasswordLength,
+                'note' => Mage::helper('adminhtml')
+                    ->__('Password must be at least of %d characters.', $minAdminPasswordLength),
             )
         );
 
diff --git app/code/core/Mage/Adminhtml/Block/System/Email/Template/Edit.php app/code/core/Mage/Adminhtml/Block/System/Email/Template/Edit.php
index b22b01a8f06..ac04b8fc31e 100644
--- app/code/core/Mage/Adminhtml/Block/System/Email/Template/Edit.php
+++ app/code/core/Mage/Adminhtml/Block/System/Email/Template/Edit.php
@@ -267,7 +267,7 @@ class Mage_Adminhtml_Block_System_Email_Template_Edit extends Mage_Adminhtml_Blo
      */
     public function getDeleteUrl()
     {
-        return $this->getUrl('*/*/delete', array('_current' => true));
+        return $this->getUrlSecure('*/*/delete', array('_current' => true));
     }
 
     /**
diff --git app/code/core/Mage/Adminhtml/Block/Widget/Grid.php app/code/core/Mage/Adminhtml/Block/Widget/Grid.php
index b17b5fd01b8..8fd4b82fcac 100644
--- app/code/core/Mage/Adminhtml/Block/Widget/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Widget/Grid.php
@@ -457,7 +457,7 @@ class Mage_Adminhtml_Block_Widget_Grid extends Mage_Adminhtml_Block_Widget
     {
         if ($this->getCollection()) {
             $field = ( $column->getFilterIndex() ) ? $column->getFilterIndex() : $column->getIndex();
-            if ($column->getFilterConditionCallback()) {
+            if ($column->getFilterConditionCallback() && $column->getFilterConditionCallback()[0] instanceof self) {
                 call_user_func($column->getFilterConditionCallback(), $this->getCollection(), $column);
             } else {
                 $cond = $column->getFilter()->getCondition();
diff --git app/code/core/Mage/Adminhtml/Model/Config/Data.php app/code/core/Mage/Adminhtml/Model/Config/Data.php
index 72bdc210d75..598e6f224ad 100644
--- app/code/core/Mage/Adminhtml/Model/Config/Data.php
+++ app/code/core/Mage/Adminhtml/Model/Config/Data.php
@@ -34,6 +34,10 @@
 
 class Mage_Adminhtml_Model_Config_Data extends Varien_Object
 {
+    const SCOPE_DEFAULT  = 'default';
+    const SCOPE_WEBSITES = 'websites';
+    const SCOPE_STORES   = 'stores';
+
     /**
      * Save config section
      * Require set: section, website, store and groups
@@ -250,13 +254,13 @@ class Mage_Adminhtml_Model_Config_Data extends Varien_Object
     protected function _getScope()
     {
         if ($this->getStore()) {
-            $scope   = 'stores';
+            $scope   = self::SCOPE_STORES;
             $scopeId = (int)Mage::getConfig()->getNode('stores/' . $this->getStore() . '/system/store/id');
         } elseif ($this->getWebsite()) {
-            $scope   = 'websites';
+            $scope   = self::SCOPE_WEBSITES;
             $scopeId = (int)Mage::getConfig()->getNode('websites/' . $this->getWebsite() . '/system/website/id');
         } else {
-            $scope   = 'default';
+            $scope   = self::SCOPE_DEFAULT;
             $scopeId = 0;
         }
         $this->setScope($scope);
@@ -302,4 +306,100 @@ class Mage_Adminhtml_Model_Config_Data extends Varien_Object
         }
         return $config;
     }
+
+    /**
+     * Secure set groups
+     *
+     * @param array $groups
+     * @return Mage_Adminhtml_Model_Config_Data
+     * @throws Mage_Core_Exception
+     */
+    public function setGroupsSecure($groups)
+    {
+        $this->_validate();
+        $this->_getScope();
+
+        $groupsSecure = array();
+        $section = $this->getSection();
+        $sections = Mage::getModel('adminhtml/config')->getSections();
+
+        foreach ($groups as $group => $groupData) {
+            $groupConfig = $sections->descend($section . '/groups/' . $group);
+            foreach ($groupData['fields'] as $field => $fieldData) {
+                $fieldName = $field;
+                if ($groupConfig && $groupConfig->clone_fields) {
+                    if ($groupConfig->clone_model) {
+                        $cloneModel = Mage::getModel((string)$groupConfig->clone_model);
+                    } else {
+                        Mage::throwException(
+                            $this->__('Config form fieldset clone model required to be able to clone fields')
+                        );
+                    }
+                    foreach ($cloneModel->getPrefixes() as $prefix) {
+                        if (strpos($field, $prefix['field']) === 0) {
+                            $field = substr($field, strlen($prefix['field']));
+                        }
+                    }
+                }
+                $fieldConfig = $sections->descend($section . '/groups/' . $group . '/fields/' . $field);
+                if (!$fieldConfig) {
+                    $node = $sections->xpath($section . '//' . $group . '[@type="group"]/fields/' . $field);
+                    if ($node) {
+                        $fieldConfig = $node[0];
+                    }
+                }
+                if (($groupConfig ? !$groupConfig->dynamic_group : true) && !$this->_isValidField($fieldConfig)) {
+                    Mage::throwException(Mage::helper('adminhtml')->__('Wrong field specified.'));
+                }
+                $groupsSecure[$group]['fields'][$fieldName] = $fieldData;
+            }
+        }
+
+        $this->setGroups($groupsSecure);
+
+        return $this;
+    }
+
+    /**
+     * Check field visibility by scope
+     *
+     * @param Mage_Core_Model_Config_Element $field
+     * @return bool
+     */
+    protected function _isValidField($field)
+    {
+        if (!$field) {
+            return false;
+        }
+
+        switch ($this->getScope()) {
+            case self::SCOPE_DEFAULT:
+                return (bool)(int)$field->show_in_default;
+                break;
+            case self::SCOPE_WEBSITES:
+                return (bool)(int)$field->show_in_website;
+                break;
+            case self::SCOPE_STORES:
+                return (bool)(int)$field->show_in_store;
+                break;
+        }
+
+        return true;
+    }
+
+    /**
+     * Select group setter is secure or not based on the configuration
+     *
+     * @param array $groups
+     * @return Mage_Adminhtml_Model_Config_Data
+     * @throws Mage_Core_Exception
+     */
+    public function setGroupsSelector($groups)
+    {
+        if (Mage::getStoreConfigFlag('admin/security/secure_system_configuration_save_disabled')) {
+            return $this->setGroups($groups);
+        }
+
+        return $this->setGroupsSecure($groups);
+    }
 }
diff --git app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
index 58ca6f67666..e2b547e4365 100644
--- app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
+++ app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
@@ -53,33 +53,26 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
      *
      * @var array
      */
-    protected $_disallowedXPathExpressions = array(
-        '*//template',
-        '*//@template',
-        '//*[@method=\'setTemplate\']',
-        '//*[@method=\'setDataUsingMethod\']//*[contains(translate(text(),
-        \'ABCDEFGHIJKLMNOPQRSTUVWXYZ\', \'abcdefghijklmnopqrstuvwxyz\'), \'template\')]/../*',
-    );
+    protected $_disallowedXPathExpressions = array();
 
     /**
      * Disallowed template name
      *
      * @var array
      */
-    protected $_disallowedBlock = array(
-        'Mage_Install_Block_End',
-        'Mage_Rss_Block_Order_New',
-        'Mage_Core_Block_Template_Zend',
-    );
+    protected $_disallowedBlock = array();
+
+    /**
+     * @var Mage_Core_Model_Layout_Validator
+     */
+    protected $_validator;
 
     /**
      * Protected expressions
      *
      * @var array
      */
-    protected $_protectedExpressions = array(
-        self::PROTECTED_ATTR_HELPER_IN_TAG_ACTION_VAR => '//action/*[@helper]',
-    );
+    protected $_protectedExpressions = array();
 
     /**
      * Construct
@@ -87,27 +80,17 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
     public function __construct()
     {
         $this->_initMessageTemplates();
+        $this->_initValidator();
     }
 
     /**
-     * Initialize messages templates with translating
+     * Returns array of validation failure messages
      *
-     * @return Mage_Adminhtml_Model_LayoutUpdate_Validator
+     * @return array
      */
-    protected function _initMessageTemplates()
+    public function getMessages()
     {
-        if (!$this->_messageTemplates) {
-            $this->_messageTemplates = array(
-                self::PROTECTED_ATTR_HELPER_IN_TAG_ACTION_VAR =>
-                    Mage::helper('adminhtml')->__('Helper attributes should not be used in custom layout updates.'),
-                self::XML_INVALID => Mage::helper('adminhtml')->__('XML data is invalid.'),
-                self::INVALID_TEMPLATE_PATH => Mage::helper('adminhtml')->__(
-                    'Invalid template path used in layout update.'
-                ),
-                self::INVALID_BLOCK_NAME => Mage::helper('adminhtml')->__('Disallowed block name for frontend.'),
-            );
-        }
-        return $this;
+        return $this->_validator->getMessages();
     }
 
     /**
@@ -124,43 +107,42 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
      */
     public function isValid($value)
     {
-        if (is_string($value)) {
-            $value = trim($value);
-            try {
-                //wrap XML value in the "config" tag because config cannot
-                //contain multiple root tags
-                $value = new Varien_Simplexml_Element('<config>' . $value . '</config>');
-            } catch (Exception $e) {
-                $this->_error(self::XML_INVALID);
-                return false;
-            }
-        } elseif (!($value instanceof Varien_Simplexml_Element)) {
-            throw new Exception(
-                Mage::helper('adminhtml')->__('XML object is not instance of "Varien_Simplexml_Element".'));
-        }
+        return $this->_validator->isValid($value);
+    }
 
-        if ($value->xpath($this->_getXpathBlockValidationExpression())) {
-            $this->_error(self::INVALID_BLOCK_NAME);
-            return false;
-        }
-        // if layout update declare custom templates then validate their paths
-        if ($templatePaths = $value->xpath($this->_getXpathValidationExpression())) {
-            try {
-                $this->_validateTemplatePath($templatePaths);
-            } catch (Exception $e) {
-                $this->_error(self::INVALID_TEMPLATE_PATH);
-                return false;
-            }
-        }
-        $this->_setValue($value);
+    /**
+     * Initialize the validator instance with populated template messages
+     */
+    protected function _initValidator()
+    {
+        $this->_validator = Mage::getModel('core/layout_validator');
+        $this->_disallowedBlock = $this->_validator->getDisallowedBlocks();
+        $this->_protectedExpressions = $this->_validator->getProtectedExpressions();
+        $this->_disallowedXPathExpressions = $this->_validator->getDisallowedXpathValidationExpression();
+        $this->_validator->setMessages($this->_messageTemplates);
+    }
 
-        foreach ($this->_protectedExpressions as $key => $xpr) {
-            if ($this->_value->xpath($xpr)) {
-                $this->_error($key);
-                return false;
-            }
+    /**
+     * Initialize messages templates with translating
+     *
+     * @return Mage_Adminhtml_Model_LayoutUpdate_Validator
+     */
+    protected function _initMessageTemplates()
+    {
+        if (!$this->_messageTemplates) {
+            $this->_messageTemplates = array(
+                self::PROTECTED_ATTR_HELPER_IN_TAG_ACTION_VAR =>
+                    Mage::helper('adminhtml')->__('Helper attributes should not be used in custom layout updates.'),
+                self::XML_INVALID => Mage::helper('adminhtml')->__('XML data is invalid.'),
+                self::INVALID_TEMPLATE_PATH => Mage::helper('adminhtml')->__(
+                    'Invalid template path used in layout update.'
+                ),
+                Mage_Core_Model_Layout_Validator::INVALID_BLOCK_NAME => Mage::helper('adminhtml')->__('Disallowed block name for frontend.'),
+                Mage_Core_Model_Layout_Validator::INVALID_XML_OBJECT_EXCEPTION =>
+                    Mage::helper('adminhtml')->__('XML object is not instance of "Varien_Simplexml_Element".'),
+            );
         }
-        return true;
+        return $this;
     }
 
     /**
@@ -168,8 +150,9 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
      *
      * @return string xPath for validate incorrect path to template
      */
-    protected function _getXpathValidationExpression() {
-        return implode(" | ", $this->_disallowedXPathExpressions);
+    protected function _getXpathValidationExpression()
+    {
+        return $this->_validator->getXpathValidationExpression();
     }
 
     /**
@@ -177,16 +160,9 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
      *
      * @return string xPath for validate incorrect block name
      */
-    protected function _getXpathBlockValidationExpression() {
-        $xpath = "";
-        if (count($this->_disallowedBlock)) {
-            foreach ($this->_disallowedBlock as $key => $value) {
-                $xpath .= $key > 0 ? " | " : '';
-                $xpath .= "//block[translate(@type, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') = ";
-                $xpath .= "translate('$value', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')]";
-            }
-        }
-        return $xpath;
+    protected function _getXpathBlockValidationExpression()
+    {
+        return $this->_validator->getXpathBlockValidationExpression();
     }
 
     /**
@@ -197,14 +173,6 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
      */
     protected function _validateTemplatePath(array $templatePaths)
     {
-        /**@var $path Varien_Simplexml_Element */
-        foreach ($templatePaths as $path) {
-            if ($path->hasChildren()) {
-                $path = stripcslashes(trim((string) $path->children(), '"'));
-            }
-            if (strpos($path, '..' . DS) !== false) {
-                throw new Exception();
-            }
-        }
+        $this->_validator->validateTemplatePath($templatePaths);
     }
 }
diff --git app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Locale.php app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Locale.php
index 20006a7de03..5db6fc446e3 100644
--- app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Locale.php
+++ app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Locale.php
@@ -45,6 +45,39 @@ class Mage_Adminhtml_Model_System_Config_Backend_Locale extends Mage_Core_Model_
         $allCurrenciesOptions = Mage::getSingleton('adminhtml/system_config_source_locale_currency_all')
             ->toOptionArray(true);
 
+        if (!function_exists('array_column')) {
+            function array_column(array $allCurrenciesOptions, $columnKey, $indexKey = null)
+            {
+                $array = array();
+                foreach ($allCurrenciesOptions as $allCurrenciesOption) {
+                    if (!array_key_exists($columnKey, $allCurrenciesOption)) {
+                        Mage::getSingleton('adminhtml/session')->addError(
+                            Mage::helper('adminhtml')->__("Key %s does not exist in array", $columnKey)
+                        );
+                        return false;
+                    }
+                    if (is_null($indexKey)) {
+                        $array[] = $allCurrenciesOption[$columnKey];
+                    } else {
+                        if (!array_key_exists($indexKey, $allCurrenciesOption)) {
+                            Mage::getSingleton('adminhtml/session')->addError(
+                                Mage::helper('adminhtml')->__("Key %s does not exist in array", $indexKey)
+                            );
+                            return false;
+                        }
+                        if (!is_scalar($allCurrenciesOption[$indexKey])) {
+                            Mage::getSingleton('adminhtml/session')->addError(
+                                Mage::helper('adminhtml')->__("Key %s does not contain scalar value", $indexKey)
+                            );
+                            return false;
+                        }
+                        $array[$allCurrenciesOption[$indexKey]] = $allCurrenciesOption[$columnKey];
+                    }
+                }
+                return $array;
+            }
+        }
+
         $allCurrenciesValues = array_column($allCurrenciesOptions, 'value');
 
         foreach ($this->getValue() as $currency) {
diff --git app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Passwordlength.php app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Passwordlength.php
new file mode 100644
index 00000000000..bb37355e048
--- /dev/null
+++ app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Passwordlength.php
@@ -0,0 +1,50 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage
+ * @copyright Copyright (c) 2006-2019 Magento, Inc. (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+/**
+ * Password length config field backend model
+ *
+ * @category    Mage
+ * @package     Mage_Adminhtml
+ * @author      Magento Core Team <core@magentocommerce.com>
+ */
+class Mage_Adminhtml_Model_System_Config_Backend_Passwordlength extends  Mage_Core_Model_Config_Data
+{
+    /**
+     * Before save processing
+     *
+     * @throws Mage_Core_Exception
+     * @return Mage_Adminhtml_Model_System_Config_Backend_Passwordlength
+     */
+    protected function _beforeSave()
+    {
+        if ((int)$this->getValue() < Mage_Core_Model_App::ABSOLUTE_MIN_PASSWORD_LENGTH) {
+            Mage::throwException(Mage::helper('adminhtml')
+                ->__('Password must be at least of %d characters.', Mage_Core_Model_App::ABSOLUTE_MIN_PASSWORD_LENGTH));
+        }
+        return $this;
+    }
+}
diff --git app/code/core/Mage/Adminhtml/controllers/Api/UserController.php app/code/core/Mage/Adminhtml/controllers/Api/UserController.php
index 6c84a1522fe..45b82ae95c7 100644
--- app/code/core/Mage/Adminhtml/controllers/Api/UserController.php
+++ app/code/core/Mage/Adminhtml/controllers/Api/UserController.php
@@ -111,6 +111,31 @@ class Mage_Adminhtml_Api_UserController extends Mage_Adminhtml_Controller_Action
                 return;
             }
             $model->setData($data);
+
+            if ($model->hasNewApiKey() && $model->getNewApiKey() === '') {
+                $model->unsNewApiKey();
+            }
+
+            if ($model->hasApiKeyConfirmation() && $model->getApiKeyConfirmation() === '') {
+                $model->unsApiKeyConfirmation();
+            }
+
+            $result = $model->validate();
+
+            if (is_array($result)) {
+                foreach ($result as $error) {
+                    $this->_getSession()->addError($error);
+                }
+                if ($id) {
+                    $this->_getSession()->setUserData($data);
+                    $this->_redirect('*/*/edit', array('user_id' => $id));
+                } else {
+                    $this->_getSession()->setUserData($data);
+                    $this->_redirect('*/*/new');
+                }
+                return;
+            }
+
             try {
                 $model->save();
                 if ( $uRoles = $this->getRequest()->getParam('roles', false) ) {
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/CategoryController.php app/code/core/Mage/Adminhtml/controllers/Catalog/CategoryController.php
index 304822786c3..3fd1dedc1d4 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/CategoryController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/CategoryController.php
@@ -499,4 +499,15 @@ class Mage_Adminhtml_Catalog_CategoryController extends Mage_Adminhtml_Controlle
     {
         return Mage::getSingleton('admin/session')->isAllowed('catalog/categories');
     }
+
+    /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions('delete');
+        return parent::preDispatch();
+    }
 }
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/Product/AttributeController.php app/code/core/Mage/Adminhtml/controllers/Catalog/Product/AttributeController.php
index fd8127654e2..4b198e9aecc 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/Product/AttributeController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/Product/AttributeController.php
@@ -244,6 +244,7 @@ class Mage_Adminhtml_Catalog_Product_AttributeController extends Mage_Adminhtml_
                     return;
                 }
 
+                $data['backend_model'] = $model->getBackendModel();
                 $data['attribute_code'] = $model->getAttributeCode();
                 $data['is_user_defined'] = $model->getIsUserDefined();
                 $data['frontend_input'] = $model->getFrontendInput();
@@ -333,7 +334,7 @@ class Mage_Adminhtml_Catalog_Product_AttributeController extends Mage_Adminhtml_
 
             // entity type check
             $model->load($id);
-            if ($model->getEntityTypeId() != $this->_entityTypeId) {
+            if ($model->getEntityTypeId() != $this->_entityTypeId || !$model->getIsUserDefined()) {
                 Mage::getSingleton('adminhtml/session')->addError(
                     Mage::helper('catalog')->__('This attribute cannot be deleted.'));
                 $this->_redirect('*/*/');
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/Product/SetController.php app/code/core/Mage/Adminhtml/controllers/Catalog/Product/SetController.php
index d7def7eecd7..32389e7c3b4 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/Product/SetController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/Product/SetController.php
@@ -208,6 +208,17 @@ class Mage_Adminhtml_Catalog_Product_SetController extends Mage_Adminhtml_Contro
         }
     }
 
+    /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions('delete');
+        return parent::preDispatch();
+    }
+
     /**
      * Define in register catalog_product entity type code as entityType
      *
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/SearchController.php app/code/core/Mage/Adminhtml/controllers/Catalog/SearchController.php
index 6d13c36d490..dd5a69fadb9 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/SearchController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/SearchController.php
@@ -190,6 +190,17 @@ class Mage_Adminhtml_Catalog_SearchController extends Mage_Adminhtml_Controller_
         $this->_redirect('*/*/index');
     }
 
+    /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions('delete', 'massDelete');
+        return parent::preDispatch();
+    }
+
     protected function _isAllowed()
     {
         return Mage::getSingleton('admin/session')->isAllowed('catalog/search');
diff --git app/code/core/Mage/Adminhtml/controllers/Cms/PageController.php app/code/core/Mage/Adminhtml/controllers/Cms/PageController.php
index a9732c2ceba..a7e56775133 100644
--- app/code/core/Mage/Adminhtml/controllers/Cms/PageController.php
+++ app/code/core/Mage/Adminhtml/controllers/Cms/PageController.php
@@ -215,6 +215,17 @@ class Mage_Adminhtml_Cms_PageController extends Mage_Adminhtml_Controller_Action
         $this->_redirect('*/*/');
     }
 
+    /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions('delete');
+        return parent::preDispatch();
+    }
+
     /**
      * Check the permission to run it
      *
diff --git app/code/core/Mage/Adminhtml/controllers/CustomerController.php app/code/core/Mage/Adminhtml/controllers/CustomerController.php
index 75fdb252d0e..386da2c46dd 100644
--- app/code/core/Mage/Adminhtml/controllers/CustomerController.php
+++ app/code/core/Mage/Adminhtml/controllers/CustomerController.php
@@ -329,9 +329,15 @@ class Mage_Adminhtml_CustomerController extends Mage_Adminhtml_Controller_Action
                 }
 
                 if (!empty($data['account']['new_password'])) {
-                    $newPassword = $data['account']['new_password'];
+                    $newPassword = trim($data['account']['new_password']);
                     if ($newPassword == 'auto') {
                         $newPassword = $customer->generatePassword();
+                    } else {
+                        $minPasswordLength = Mage::getModel('customer/customer')->getMinPasswordLength();
+                        if (Mage::helper('core/string')->strlen($newPassword) < $minPasswordLength) {
+                            Mage::throwException(Mage::helper('customer')
+                                ->__('The minimum password length is %s', $minPasswordLength));
+                        }
                     }
                     $customer->changePassword($newPassword);
                     $customer->sendPasswordReminderEmail();
diff --git app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php
index 9e5a5e7dbfc..48d2ff905e3 100644
--- app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php
+++ app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php
@@ -249,4 +249,15 @@ class Mage_Adminhtml_Newsletter_TemplateController extends Mage_Adminhtml_Contro
         $this->getLayout()->getBlock('preview_form')->setFormData($data);
         $this->renderLayout();
     }
+
+    /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions('delete');
+        return parent::preDispatch();
+    }
 }
diff --git app/code/core/Mage/Adminhtml/controllers/Permissions/BlockController.php app/code/core/Mage/Adminhtml/controllers/Permissions/BlockController.php
index eb91f850de1..97b81ea03ec 100644
--- app/code/core/Mage/Adminhtml/controllers/Permissions/BlockController.php
+++ app/code/core/Mage/Adminhtml/controllers/Permissions/BlockController.php
@@ -204,6 +204,17 @@ class Mage_Adminhtml_Permissions_BlockController extends Mage_Adminhtml_Controll
             );
     }
 
+    /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions('delete');
+        return parent::preDispatch();
+    }
+
     /**
      * Check permissions before allow edit list of blocks
      *
diff --git app/code/core/Mage/Adminhtml/controllers/Sales/OrderController.php app/code/core/Mage/Adminhtml/controllers/Sales/OrderController.php
index 3b957b77ff6..68f7d882498 100644
--- app/code/core/Mage/Adminhtml/controllers/Sales/OrderController.php
+++ app/code/core/Mage/Adminhtml/controllers/Sales/OrderController.php
@@ -757,4 +757,15 @@ class Mage_Adminhtml_Sales_OrderController extends Mage_Adminhtml_Controller_Act
             $this->_redirect('*/*/');
         }
     }
+
+    /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions('cancel', 'massCancel');
+        return parent::preDispatch();
+    }
 }
diff --git app/code/core/Mage/Adminhtml/controllers/System/ConfigController.php app/code/core/Mage/Adminhtml/controllers/System/ConfigController.php
index c5870938da9..7138e99aff8 100644
--- app/code/core/Mage/Adminhtml/controllers/System/ConfigController.php
+++ app/code/core/Mage/Adminhtml/controllers/System/ConfigController.php
@@ -149,7 +149,7 @@ class Mage_Adminhtml_System_ConfigController extends Mage_Adminhtml_Controller_A
                 ->setSection($section)
                 ->setWebsite($website)
                 ->setStore($store)
-                ->setGroups($groups)
+                ->setGroupsSelector($groups)
                 ->save();
 
             // reinit configuration
diff --git app/code/core/Mage/Adminhtml/controllers/System/Email/TemplateController.php app/code/core/Mage/Adminhtml/controllers/System/Email/TemplateController.php
index e694962b913..9e7df43d627 100644
--- app/code/core/Mage/Adminhtml/controllers/System/Email/TemplateController.php
+++ app/code/core/Mage/Adminhtml/controllers/System/Email/TemplateController.php
@@ -107,7 +107,7 @@ class Mage_Adminhtml_System_Email_TemplateController extends Mage_Adminhtml_Cont
         }
 
         try {
-            $allowedHtmlTags = ['template_text', 'styles'];
+            $allowedHtmlTags = ['template_text', 'styles', 'variables'];
             if (Mage::helper('adminhtml')->hasTags($request->getParams(), $allowedHtmlTags)) {
                 Mage::throwException(Mage::helper('adminhtml')->__('Invalid template data.'));
             }
@@ -204,6 +204,17 @@ class Mage_Adminhtml_System_Email_TemplateController extends Mage_Adminhtml_Cont
         $this->getResponse()->setBody(Mage::helper('core')->jsonEncode($template->getData()));
     }
 
+    /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions('delete');
+        return parent::preDispatch();
+    }
+
     /**
      * Load email template from request
      *
diff --git app/code/core/Mage/Adminhtml/controllers/Tax/RuleController.php app/code/core/Mage/Adminhtml/controllers/Tax/RuleController.php
index 40b64833cb4..cbf77d9a3be 100644
--- app/code/core/Mage/Adminhtml/controllers/Tax/RuleController.php
+++ app/code/core/Mage/Adminhtml/controllers/Tax/RuleController.php
@@ -170,4 +170,15 @@ class Mage_Adminhtml_Tax_RuleController extends Mage_Adminhtml_Controller_Action
     {
         return Mage::getSingleton('admin/session')->isAllowed('sales/tax/rules');
     }
+
+    /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions('delete');
+        return parent::preDispatch();
+    }
 }
diff --git app/code/core/Mage/Api/Model/User.php app/code/core/Mage/Api/Model/User.php
index fc6753408d7..1459a1c4fed 100644
--- app/code/core/Mage/Api/Model/User.php
+++ app/code/core/Mage/Api/Model/User.php
@@ -241,7 +241,78 @@ class Mage_Api_Model_User extends Mage_Core_Model_Abstract
 
     protected function _getEncodedApiKey($apiKey)
     {
-        return Mage::helper('core')->getHash($apiKey, 2);
+        return Mage::helper('core')->getHashPassword($apiKey, Mage_Admin_Model_User::HASH_SALT_LENGTH);
     }
 
+
+    /**
+     * Validate user attribute values.
+     *
+     * @return array|bool
+     * @throws Zend_Validate_Exception
+     */
+    public function validate()
+    {
+        $errors = new ArrayObject();
+
+        if (!Zend_Validate::is($this->getUsername(), 'NotEmpty')) {
+            $errors[] = Mage::helper('api')->__('User Name is required field.');
+        }
+
+        if (!Zend_Validate::is($this->getFirstname(), 'NotEmpty')) {
+            $errors[] = Mage::helper('api')->__('First Name is required field.');
+        }
+
+        if (!Zend_Validate::is($this->getLastname(), 'NotEmpty')) {
+            $errors[] = Mage::helper('api')->__('Last Name is required field.');
+        }
+
+        if (!Zend_Validate::is($this->getEmail(), 'EmailAddress')) {
+            $errors[] = Mage::helper('api')->__('Please enter a valid email.');
+        }
+
+        if ($this->hasNewApiKey()) {
+            $apiKey = $this->getNewApiKey();
+        } elseif ($this->hasApiKey()) {
+            $apiKey = $this->getApiKey();
+        }
+
+        if (isset($apiKey)) {
+            $minCustomerPasswordLength = $this->_getMinCustomerPasswordLength();
+            if (strlen($apiKey) < $minCustomerPasswordLength) {
+                $errors[] = Mage::helper('api')
+                    ->__('Api Key must be at least of %d characters.', $minCustomerPasswordLength);
+            }
+
+            if (!preg_match('/[a-z]/iu', $apiKey) || !preg_match('/[0-9]/u', $apiKey)) {
+                $errors[] = Mage::helper('api')
+                    ->__('Api Key must include both numeric and alphabetic characters.');
+            }
+
+            if ($this->hasApiKeyConfirmation() && $apiKey != $this->getApiKeyConfirmation()) {
+                $errors[] = Mage::helper('api')->__('Api Key confirmation must be same as Api Key.');
+            }
+        }
+
+        if ($this->userExists()) {
+            $errors[] = Mage::helper('api')
+                ->__('A user with the same user name or email already exists.');
+        }
+
+        if (count($errors) === 0) {
+            return true;
+        }
+
+        return (array) $errors;
+    }
+
+    /**
+     * Get min customer password length
+     *
+     * @return int
+     */
+    protected function _getMinCustomerPasswordLength()
+    {
+        return Mage::getSingleton('customer/customer')->getMinPasswordLength();
+    }
 }
diff --git app/code/core/Mage/Api/etc/config.xml app/code/core/Mage/Api/etc/config.xml
index e5b35d89ca9..31a82e91b30 100644
--- app/code/core/Mage/Api/etc/config.xml
+++ app/code/core/Mage/Api/etc/config.xml
@@ -28,7 +28,7 @@
 <config>
     <modules>
         <Mage_Api>
-            <version>1.6.0.0</version>
+            <version>1.6.0.0.1.2</version>
         </Mage_Api>
     </modules>
     <global>
diff --git app/code/core/Mage/Api/sql/api_setup/mysql4-upgrade-1.6.0.0.1.1-1.6.0.0.1.2.php app/code/core/Mage/Api/sql/api_setup/mysql4-upgrade-1.6.0.0.1.1-1.6.0.0.1.2.php
new file mode 100644
index 00000000000..bc3f96e1c0c
--- /dev/null
+++ app/code/core/Mage/Api/sql/api_setup/mysql4-upgrade-1.6.0.0.1.1-1.6.0.0.1.2.php
@@ -0,0 +1,41 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage
+ * @copyright Copyright (c) 2006-2019 Magento, Inc. (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+/* @var $this Mage_Core_Model_Resource_Setup */
+$this->startSetup();
+
+$this->getConnection()->changeColumn(
+    $this->getTable('api/user'),
+    'api_key',
+    'api_key',
+    array(
+        'type' => Varien_Db_Ddl_Table::TYPE_TEXT,
+        'length' => 255,
+        'comment' => 'Api key'
+    )
+);
+
+$this->endSetup();
diff --git app/code/core/Mage/Catalog/Block/Product/Abstract.php app/code/core/Mage/Catalog/Block/Product/Abstract.php
index 0d9ea6f1cd7..146c246fa23 100644
--- app/code/core/Mage/Catalog/Block/Product/Abstract.php
+++ app/code/core/Mage/Catalog/Block/Product/Abstract.php
@@ -114,21 +114,7 @@ abstract class Mage_Catalog_Block_Product_Abstract extends Mage_Core_Block_Templ
      */
     public function getAddToCartUrl($product, $additional = array())
     {
-        if (!$product->getTypeInstance(true)->hasRequiredOptions($product)) {
-            return $this->helper('checkout/cart')->getAddUrl($product, $additional);
-        }
-        $additional = array_merge(
-            $additional,
-            array(Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey())
-        );
-        if (!isset($additional['_escape'])) {
-            $additional['_escape'] = true;
-        }
-        if (!isset($additional['_query'])) {
-            $additional['_query'] = array();
-        }
-        $additional['_query']['options'] = 'cart';
-        return $this->getProductUrl($product, $additional);
+        return $this->getAddToCartUrlCustom($product, $additional);
     }
 
     /**
@@ -154,15 +140,7 @@ abstract class Mage_Catalog_Block_Product_Abstract extends Mage_Core_Block_Templ
      */
     public function getSubmitUrl($product, $additional = array())
     {
-        $submitRouteData = $this->getData('submit_route_data');
-        if ($submitRouteData) {
-            $route = $submitRouteData['route'];
-            $params = isset($submitRouteData['params']) ? $submitRouteData['params'] : array();
-            $submitUrl = $this->getUrl($route, array_merge($params, $additional));
-        } else {
-            $submitUrl = $this->getAddToCartUrl($product, $additional);
-        }
-        return $submitUrl;
+        return $this->getSubmitUrlCustom($product, $additional);
     }
 
     /**
@@ -173,7 +151,7 @@ abstract class Mage_Catalog_Block_Product_Abstract extends Mage_Core_Block_Templ
      */
     public function getAddToWishlistUrl($product)
     {
-        return $this->helper('wishlist')->getAddUrl($product);
+        return $this->getAddToWishlistUrlCustom($product);
     }
 
     /**
@@ -184,7 +162,7 @@ abstract class Mage_Catalog_Block_Product_Abstract extends Mage_Core_Block_Templ
      */
     public function getAddToCompareUrl($product)
     {
-        return $this->helper('catalog/product_compare')->getAddUrl($product);
+        return $this->getAddToCompareUrlCustom($product);
     }
 
     public function getMinimalQty($product)
@@ -605,6 +583,36 @@ abstract class Mage_Catalog_Block_Product_Abstract extends Mage_Core_Block_Templ
         return $product->getCanShowPrice() !== false;
     }
 
+    /**
+     * Return link to Add to Wishlist with or without Form Key
+     *
+     * @param Mage_Catalog_Model_Product $product
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function getAddToWishlistUrlCustom($product, $addFormKey = true)
+    {
+        if (!$addFormKey) {
+            return $this->helper('wishlist')->getAddUrlWithCustomParams($product, array(), false);
+        }
+        return $this->helper('wishlist')->getAddUrl($product);
+    }
+
+    /**
+     * Retrieve Add Product to Compare Products List URL with or without Form Key
+     *
+     * @param Mage_Catalog_Model_Product $product
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function getAddToCompareUrlCustom($product, $addFormKey = true)
+    {
+        if (!$addFormKey) {
+            return $this->helper('catalog/product_compare')->getAddUrlCustom($product, false);
+        }
+        return $this->helper('catalog/product_compare')->getAddUrl($product);
+    }
+
     /**
      * If exists price template block, retrieve price blocks from it
      *
@@ -624,4 +632,64 @@ abstract class Mage_Catalog_Block_Product_Abstract extends Mage_Core_Block_Templ
 
         return $this;
     }
+
+    /**
+     * Retrieve url for add product to cart with or without Form Key
+     * Will return product view page URL if product has required options
+     *
+     * @param Mage_Catalog_Model_Product $product
+     * @param array $additional
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function  getAddToCartUrlCustom($product, $additional = array(), $addFormKey = true)
+    {
+        if (!$product->getTypeInstance(true)->hasRequiredOptions($product)) {
+            if (!$addFormKey) {
+                return $this->helper('checkout/cart')->getAddUrlCustom($product, $additional, false);
+            }
+            return $this->helper('checkout/cart')->getAddUrl($product, $additional);
+        }
+        if ($addFormKey) {
+            $additional = array_merge(
+                $additional,
+                array(Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey())
+            );
+        }
+        if (!isset($additional['_escape'])) {
+            $additional['_escape'] = true;
+        }
+        if (!isset($additional['_query'])) {
+            $additional['_query'] = array();
+        }
+        $additional['_query']['options'] = 'cart';
+        return $this->getProductUrl($product, $additional);
+    }
+
+    /**
+     * Retrieves url for form submitting:
+     * some objects can use setSubmitRouteData() to set route and params for form submitting,
+     * otherwise default url will be used with or without Form Key
+     *
+     * @param Mage_Catalog_Model_Product $product
+     * @param array $additional
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function getSubmitUrlCustom($product, $additional = array(), $addFormKey = true)
+    {
+        $submitRouteData = $this->getData('submit_route_data');
+        if ($submitRouteData) {
+            $route = $submitRouteData['route'];
+            $params = isset($submitRouteData['params']) ? $submitRouteData['params'] : array();
+            $submitUrl = $this->getUrl($route, array_merge($params, $additional));
+        } else {
+            if ($addFormKey) {
+                $submitUrl = $this->getAddToCartUrl($product, $additional);
+            } else {
+                $submitUrl = $this->getAddToCartUrlCustom($product, $additional, false);
+            }
+        }
+        return $submitUrl;
+    }
 }
diff --git app/code/core/Mage/Catalog/Block/Product/Compare/List.php app/code/core/Mage/Catalog/Block/Product/Compare/List.php
index 91c3347e8b9..628e82bfc6c 100644
--- app/code/core/Mage/Catalog/Block/Product/Compare/List.php
+++ app/code/core/Mage/Catalog/Block/Product/Compare/List.php
@@ -70,14 +70,7 @@ class Mage_Catalog_Block_Product_Compare_List extends Mage_Catalog_Block_Product
      */
     public function getAddToWishlistUrl($product)
     {
-        $continueUrl    = Mage::helper('core')->urlEncode($this->getUrl('customer/account'));
-        $urlParamName   = Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED;
-
-        $params = array(
-            $urlParamName   => $continueUrl
-        );
-
-        return $this->helper('wishlist')->getAddUrlWithParams($product, $params);
+        return $this->getAddToWishlistUrlCustom($product);
     }
 
     /**
@@ -188,4 +181,26 @@ class Mage_Catalog_Block_Product_Compare_List extends Mage_Catalog_Block_Product
         $this->_customerId = $id;
         return $this;
     }
+
+    /**
+     * Retrieve url for adding product to wishlist with params with or without Form Key
+     *
+     * @param Mage_Catalog_Model_Product $product
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function getAddToWishlistUrlCustom($product, $addFormKey = true)
+    {
+        $continueUrl = Mage::helper('core')->urlEncode($this->getUrl('customer/account'));
+        $params = array(
+            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $continueUrl
+        );
+
+        if (!$addFormKey) {
+            return $this->helper('wishlist')->getAddUrlWithCustomParams($product, $params, false);
+        }
+
+        return $this->helper('wishlist')->getAddUrlWithParams($product, $params);
+    }
+
 }
diff --git app/code/core/Mage/Catalog/Block/Product/Price.php app/code/core/Mage/Catalog/Block/Product/Price.php
index 8e359abbb3f..09c1f310ecf 100644
--- app/code/core/Mage/Catalog/Block/Product/Price.php
+++ app/code/core/Mage/Catalog/Block/Product/Price.php
@@ -128,7 +128,7 @@ class Mage_Catalog_Block_Product_Price extends Mage_Core_Block_Template
      */
     public function getAddToCartUrl($product, $additional = array())
     {
-        return $this->helper('checkout/cart')->getAddUrl($product, $additional);
+        return $this->getAddToCartUrlCustom($product, $additional);
     }
 
     /**
@@ -155,4 +155,20 @@ class Mage_Catalog_Block_Product_Price extends Mage_Core_Block_Template
         $html = $this->hasRealPriceHtml() ? $this->getRealPriceHtml() : $product->getRealPriceHtml();
         return Mage::helper('core')->jsonEncode($html);
     }
+
+    /**
+     * Retrieve url for direct adding product to cart with or without Form Key
+     *
+     * @param Mage_Catalog_Model_Product $product
+     * @param array $additional
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function getAddToCartUrlCustom($product, $additional = array(), $addFormKey = true)
+    {
+        if (!$addFormKey) {
+            return $this->helper('checkout/cart')->getAddUrlCustom($product, $additional, false);
+        }
+        return $this->helper('checkout/cart')->getAddUrl($product, $additional);
+    }
 }
diff --git app/code/core/Mage/Catalog/Block/Product/View.php app/code/core/Mage/Catalog/Block/Product/View.php
index 4507d5ca093..7011c51a0a9 100644
--- app/code/core/Mage/Catalog/Block/Product/View.php
+++ app/code/core/Mage/Catalog/Block/Product/View.php
@@ -112,19 +112,7 @@ class Mage_Catalog_Block_Product_View extends Mage_Catalog_Block_Product_Abstrac
      */
     public function getAddToCartUrl($product, $additional = array())
     {
-        if ($this->hasCustomAddToCartUrl()) {
-            return $this->getCustomAddToCartUrl();
-        }
-
-        if ($this->getRequest()->getParam('wishlist_next')) {
-            $additional['wishlist_next'] = 1;
-        }
-
-        $addUrlKey = Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED;
-        $addUrlValue = Mage::getUrl('*/*/*', array('_use_rewrite' => true, '_current' => false));
-        $additional[$addUrlKey] = Mage::helper('core')->urlEncode($addUrlValue);
-
-        return $this->helper('checkout/cart')->getAddUrl($product, $additional);
+        return $this->getAddToCartUrlCustom($product, $additional);
     }
 
     /**
@@ -247,4 +235,34 @@ class Mage_Catalog_Block_Product_View extends Mage_Catalog_Block_Product_Abstrac
 
         return $qty;
     }
+
+    /**
+     * Retrieve url for direct adding product to cart with or without Form Key
+     *
+     * @param Mage_Catalog_Model_Product $product
+     * @param array $additional
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function getAddToCartUrlCustom($product, $additional = array(), $addFormKey = true)
+    {
+        if (!$addFormKey && $this->hasCustomAddToCartPostUrl()) {
+            return $this->getCustomAddToCartPostUrl();
+        } elseif ($this->hasCustomAddToCartUrl()) {
+            return $this->getCustomAddToCartUrl();
+        }
+
+        if ($this->getRequest()->getParam('wishlist_next')) {
+            $additional['wishlist_next'] = 1;
+        }
+
+        $addUrlValue = Mage::getUrl('*/*/*', array('_use_rewrite' => true, '_current' => true));
+        $additional[Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED] =
+            Mage::helper('core')->urlEncode($addUrlValue);
+
+        if (!$addFormKey) {
+            return $this->helper('checkout/cart')->getAddUrlCustom($product, $additional, false);
+        }
+        return $this->helper('checkout/cart')->getAddUrl($product, $additional);
+    }
 }
diff --git app/code/core/Mage/Catalog/Helper/Product/Compare.php app/code/core/Mage/Catalog/Helper/Product/Compare.php
index 2c1df18a245..82d0bde8d99 100644
--- app/code/core/Mage/Catalog/Helper/Product/Compare.php
+++ app/code/core/Mage/Catalog/Helper/Product/Compare.php
@@ -100,11 +100,7 @@ class Mage_Catalog_Helper_Product_Compare extends Mage_Core_Helper_Url
      */
     protected function _getUrlParams($product)
     {
-        return array(
-            'product' => $product->getId(),
-            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->getEncodedUrl(),
-            Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey()
-        );
+        return $this->_getUrlCustomParams($product);
     }
 
     /**
@@ -115,7 +111,7 @@ class Mage_Catalog_Helper_Product_Compare extends Mage_Core_Helper_Url
      */
     public function getAddUrl($product)
     {
-        return $this->_getUrl('catalog/product_compare/add', $this->_getUrlParams($product));
+        return $this->getAddUrlCustom($product);
     }
 
     /**
@@ -126,15 +122,7 @@ class Mage_Catalog_Helper_Product_Compare extends Mage_Core_Helper_Url
      */
     public function getAddToWishlistUrl($product)
     {
-        $beforeCompareUrl = Mage::getSingleton('catalog/session')->getBeforeCompareUrl();
-
-        $params = array(
-            'product' => $product->getId(),
-            Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey(),
-            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->getEncodedUrl($beforeCompareUrl)
-        );
-
-        return $this->_getUrl('wishlist/index/add', $params);
+        return $this->getAddToWishlistUrlCustom($product);
     }
 
     /**
@@ -145,14 +133,7 @@ class Mage_Catalog_Helper_Product_Compare extends Mage_Core_Helper_Url
      */
     public function getAddToCartUrl($product)
     {
-        $beforeCompareUrl = $this->_getSingletonModel('catalog/session')->getBeforeCompareUrl();
-        $params = array(
-            'product' => $product->getId(),
-            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->getEncodedUrl($beforeCompareUrl),
-            Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey()
-        );
-
-        return $this->_getUrl('checkout/cart/add', $params);
+        return $this->getAddToCartUrlCustom($product);
     }
 
     /**
@@ -314,4 +295,71 @@ class Mage_Catalog_Helper_Product_Compare extends Mage_Core_Helper_Url
         $this->_customerId = $id;
         return $this;
     }
+
+    /**
+     * Retrieve url for adding product to conpare list with or without Form Key
+     *
+     * @param Mage_Catalog_Model_Product $product
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function getAddUrlCustom($product, $addFormKey = true)
+    {
+        return $this->_getUrl('catalog/product_compare/add', $this->_getUrlCustomParams($product, $addFormKey));
+    }
+
+    /**
+     * Retrive add to wishlist url with or without Form Key
+     *
+     * @param Mage_Catalog_Model_Product $product
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function getAddToWishlistUrlCustom($product, $addFormKey = true)
+    {
+        $beforeCompareUrl = Mage::getSingleton('catalog/session')->getBeforeCompareUrl();
+        $params = $this->_getUrlCustomParams($product, $addFormKey, $beforeCompareUrl);
+
+        return $this->_getUrl('wishlist/index/add', $params);
+    }
+
+    /**
+     * Retrive add to cart url with or without Form Key
+     *
+     * @param Mage_Catalog_Model_Product $product
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function getAddToCartUrlCustom($product, $addFormKey = true)
+    {
+        $beforeCompareUrl = Mage::getSingleton('catalog/session')->getBeforeCompareUrl();
+        $params = array(
+            'product' => $product->getId(),
+            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->getEncodedUrl($beforeCompareUrl),
+        );
+        if ($addFormKey) {
+            $params[Mage_Core_Model_Url::FORM_KEY] = Mage::getSingleton('core/session')->getFormKey();
+        }
+
+        return $this->_getUrl('checkout/cart/add', $params);
+    }
+
+    /**
+     * Get parameters used for build add product to compare list urls with or without Form Key
+     *
+     * @param   Mage_Catalog_Model_Product $product
+     * @param bool $addFormKey
+     * @return  array
+     */
+    protected function _getUrlCustomParams($product, $addFormKey = true, $url = null)
+    {
+        $params = array(
+            'product' => $product->getId(),
+            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->getEncodedUrl($url),
+        );
+        if ($addFormKey) {
+            $params[Mage_Core_Model_Url::FORM_KEY] = Mage::getSingleton('core/session')->getFormKey();
+        }
+        return $params;
+    }
 }
diff --git app/code/core/Mage/Catalog/Model/Design.php app/code/core/Mage/Catalog/Model/Design.php
index da83940ead5..3de03d9412c 100644
--- app/code/core/Mage/Catalog/Model/Design.php
+++ app/code/core/Mage/Catalog/Model/Design.php
@@ -374,9 +374,19 @@ class Mage_Catalog_Model_Design extends Mage_Core_Model_Abstract
         $date = $object->getCustomDesignDate();
         if (array_key_exists('from', $date) && array_key_exists('to', $date)
             && Mage::app()->getLocale()->isStoreDateInInterval(null, $date['from'], $date['to'])) {
-                $settings->setCustomDesign($object->getCustomDesign())
-                    ->setPageLayout($object->getPageLayout())
-                    ->setLayoutUpdates((array)$object->getCustomLayoutUpdate());
+            $customLayout = $object->getCustomLayoutUpdate();
+            if ($customLayout) {
+                try {
+                    if (!Mage::getModel('core/layout_validator')->isValid($customLayout)) {
+                        $customLayout = '';
+                    }
+                } catch (Exception $e) {
+                    $customLayout = '';
+                }
+            }
+            $settings->setCustomDesign($object->getCustomDesign())
+                ->setPageLayout($object->getPageLayout())
+                ->setLayoutUpdates((array)$customLayout);
         }
         return $settings;
     }
diff --git app/code/core/Mage/Catalog/etc/config.xml app/code/core/Mage/Catalog/etc/config.xml
index d338271c314..703809bbdbf 100644
--- app/code/core/Mage/Catalog/etc/config.xml
+++ app/code/core/Mage/Catalog/etc/config.xml
@@ -28,7 +28,7 @@
 <config>
     <modules>
         <Mage_Catalog>
-            <version>1.6.0.0.5</version>
+            <version>1.6.0.0.5.1.2</version>
         </Mage_Catalog>
     </modules>
     <admin>
diff --git app/code/core/Mage/Catalog/sql/catalog_setup/upgrade-1.6.0.0.5.1.1-1.6.0.0.5.1.2.php app/code/core/Mage/Catalog/sql/catalog_setup/upgrade-1.6.0.0.5.1.1-1.6.0.0.5.1.2.php
new file mode 100644
index 00000000000..46d4b6e52c3
--- /dev/null
+++ app/code/core/Mage/Catalog/sql/catalog_setup/upgrade-1.6.0.0.5.1.1-1.6.0.0.5.1.2.php
@@ -0,0 +1,44 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage
+ * @copyright Copyright (c) 2006-2019 Magento, Inc. (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+/* @var $installer Mage_Catalog_Model_Resource_Setup */
+$installer = $this;
+$attributeId = 'custom_layout_update';
+
+$entitiesToUpgrade = [
+    $installer->getEntityTypeId('catalog_product'),
+    $installer->getEntityTypeId('catalog_category'),
+];
+foreach ($entitiesToUpgrade as $entityTypeId) {
+    if ($this->getAttributeId($entityTypeId, $attributeId)) {
+        $installer->updateAttribute(
+            $entityTypeId,
+            $attributeId,
+            'backend_model',
+            'catalog/attribute_backend_customlayoutupdate'
+        );
+    }
+}
diff --git app/code/core/Mage/Checkout/Block/Cart/Item/Renderer.php app/code/core/Mage/Checkout/Block/Cart/Item/Renderer.php
index 5a01e696b4b..2947f1486d4 100644
--- app/code/core/Mage/Checkout/Block/Cart/Item/Renderer.php
+++ app/code/core/Mage/Checkout/Block/Cart/Item/Renderer.php
@@ -203,14 +203,26 @@ class Mage_Checkout_Block_Cart_Item_Renderer extends Mage_Core_Block_Template
      */
     public function getDeleteUrl()
     {
-        return $this->getUrl(
-            'checkout/cart/delete',
-            array(
-                'id'=>$this->getItem()->getId(),
-                'form_key' => Mage::getSingleton('core/session')->getFormKey(),
-                Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->helper('core/url')->getEncodedUrl()
-            )
+        return $this->getDeleteUrlCustom();
+    }
+
+    /**
+     * Get item delete url with or without Form Key
+     *
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function getDeleteUrlCustom($addFormKey = true)
+    {
+        $params = array(
+            'id' => $this->getItem()->getId(),
+            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->helper('core/url')->getEncodedUrl(),
         );
+        if ($addFormKey) {
+            $params[Mage_Core_Model_Url::FORM_KEY] = Mage::getSingleton('core/session')->getFormKey();
+        }
+
+        return $this->getUrl('checkout/cart/delete', $params);
     }
 
     /**
diff --git app/code/core/Mage/Checkout/Helper/Cart.php app/code/core/Mage/Checkout/Helper/Cart.php
index aaf1b161115..80d9e4d4f2f 100644
--- app/code/core/Mage/Checkout/Helper/Cart.php
+++ app/code/core/Mage/Checkout/Helper/Cart.php
@@ -55,28 +55,7 @@ class Mage_Checkout_Helper_Cart extends Mage_Core_Helper_Url
      */
     public function getAddUrl($product, $additional = array())
     {
-        $routeParams = array(
-            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->_getHelperInstance('core')
-                ->urlEncode($this->getCurrentUrl()),
-            'product' => $product->getEntityId(),
-            Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey()
-        );
-
-        if (!empty($additional)) {
-            $routeParams = array_merge($routeParams, $additional);
-        }
-
-        if ($product->hasUrlDataObject()) {
-            $routeParams['_store'] = $product->getUrlDataObject()->getStoreId();
-            $routeParams['_store_to_url'] = true;
-        }
-
-        if ($this->_getRequest()->getRouteName() == 'checkout'
-            && $this->_getRequest()->getControllerName() == 'cart') {
-            $routeParams['in_cart'] = 1;
-        }
-
-        return $this->_getUrl('checkout/cart/add', $routeParams);
+        return $this->getAddUrlCustom($product, $additional);
     }
 
     /**
@@ -175,4 +154,39 @@ class Mage_Checkout_Helper_Cart extends Mage_Core_Helper_Url
     {
         return Mage::getStoreConfigFlag(self::XML_PATH_REDIRECT_TO_CART, $store);
     }
+
+    /**
+     * Retrieve url for add product to cart with or without Form Key
+     *
+     * @param Mage_Catalog_Model_Product $product
+     * @param array $additional
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function getAddUrlCustom($product, $additional = array(), $addFormKey = true)
+    {
+        $routeParams = array(
+            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->_getHelperInstance('core')
+                ->urlEncode($this->getCurrentUrl()),
+            'product' => $product->getEntityId(),
+        );
+        if ($addFormKey) {
+            $routeParams[Mage_Core_Model_Url::FORM_KEY] = $this->_getSingletonModel('core/session')->getFormKey();
+        }
+        if (!empty($additional)) {
+            $routeParams = array_merge($routeParams, $additional);
+        }
+        if ($product->hasUrlDataObject()) {
+            $routeParams['_store'] = $product->getUrlDataObject()->getStoreId();
+            $routeParams['_store_to_url'] = true;
+        }
+        if (
+            $this->_getRequest()->getRouteName() == 'checkout'
+            && $this->_getRequest()->getControllerName() == 'cart'
+        ) {
+            $routeParams['in_cart'] = 1;
+        }
+
+        return $this->_getUrl('checkout/cart/add', $routeParams);
+    }
 }
diff --git app/code/core/Mage/Checkout/Model/Session.php app/code/core/Mage/Checkout/Model/Session.php
index 66c6e5e64d2..971156f7820 100644
--- app/code/core/Mage/Checkout/Model/Session.php
+++ app/code/core/Mage/Checkout/Model/Session.php
@@ -107,8 +107,6 @@ class Mage_Checkout_Model_Session extends Mage_Core_Model_Session_Abstract
         if ($this->_quote === null) {
             $quote = Mage::getModel('sales/quote')
                 ->setStoreId(Mage::app()->getStore()->getId());
-            $customerSession = Mage::getSingleton('customer/session');
-
             /** @var $quote Mage_Sales_Model_Quote */
             if ($this->getQuoteId()) {
                 if ($this->_loadInactive) {
@@ -116,13 +114,7 @@ class Mage_Checkout_Model_Session extends Mage_Core_Model_Session_Abstract
                 } else {
                     $quote->loadActive($this->getQuoteId());
                 }
-                if (
-                    $quote->getId()
-                    && (
-                        ($customerSession->isLoggedIn() && $customerSession->getId() == $quote->getCustomerId())
-                        || (!$customerSession->isLoggedIn() && !$quote->getCustomerId())
-                    )
-                ) {
+                if ($quote->getId()) {
                     /**
                      * If current currency code of quote is not equal current currency code of store,
                      * need recalculate totals of quote. It is possible if customer use currency switcher or
@@ -139,16 +131,16 @@ class Mage_Checkout_Model_Session extends Mage_Core_Model_Session_Abstract
                         $quote->load($this->getQuoteId());
                     }
                 } else {
-                    $quote->unsetData();
                     $this->setQuoteId(null);
                 }
             }
 
+            $customerSession = Mage::getSingleton('customer/session');
+
             if (!$this->getQuoteId()) {
                 if ($customerSession->isLoggedIn() || $this->_customer) {
                     $customer = ($this->_customer) ? $this->_customer : $customerSession->getCustomer();
                     $quote->loadByCustomer($customer);
-                    $quote->setCustomer($customer);
                     $this->setQuoteId($quote->getId());
                 } else {
                     $quote->setIsCheckoutCart(true);
diff --git app/code/core/Mage/Cms/Block/Widget/Block.php app/code/core/Mage/Cms/Block/Widget/Block.php
index b274504e57e..e0859be55ce 100644
--- app/code/core/Mage/Cms/Block/Widget/Block.php
+++ app/code/core/Mage/Cms/Block/Widget/Block.php
@@ -66,11 +66,27 @@ class Mage_Cms_Block_Widget_Block extends Mage_Core_Block_Template implements Ma
                 /* @var $helper Mage_Cms_Helper_Data */
                 $helper = Mage::helper('cms');
                 $processor = $helper->getBlockTemplateProcessor();
-                $this->setText($processor->filter($block->getContent()));
+                if ($this->isRequestFromAdminArea()) {
+                    $this->setText($processor->filter(
+                        Mage::getSingleton('core/input_filter_maliciousCode')->filter($block->getContent())
+                    ));
+                } else {
+                    $this->setText($processor->filter($block->getContent()));
+                }
             }
         }
 
         unset(self::$_widgetUsageMap[$blockHash]);
         return $this;
     }
+
+    /**
+     * Check is request goes from admin area
+     *
+     * @return bool
+     */
+    public function isRequestFromAdminArea()
+    {
+        return $this->getRequest()->getRouteName() === Mage_Core_Model_App_Area::AREA_ADMINHTML;
+    }
 }
diff --git app/code/core/Mage/Core/Block/Abstract.php app/code/core/Mage/Core/Block/Abstract.php
index 3fda9ec07aa..822b1221ad5 100644
--- app/code/core/Mage/Core/Block/Abstract.php
+++ app/code/core/Mage/Core/Block/Abstract.php
@@ -1241,6 +1241,16 @@ abstract class Mage_Core_Block_Abstract extends Varien_Object
         return $this->getData('cache_lifetime');
     }
 
+    /**
+     * Retrieve Session Form Key
+     *
+     * @return string
+     */
+    public function getFormKey()
+    {
+        return Mage::getSingleton('core/session')->getFormKey();
+    }
+
     /**
      * Load block html from cache storage
      *
@@ -1268,4 +1278,14 @@ abstract class Mage_Core_Block_Abstract extends Varien_Object
         Mage::app()->saveCache($data, $this->getCacheKey(), $this->getCacheTags(), $this->getCacheLifetime());
         return $this;
     }
+
+    /**
+     * Checks is request Url is secure
+     *
+     * @return bool
+     */
+    protected function _isSecure()
+    {
+        return Mage::app()->getFrontController()->getRequest()->isSecure();
+    }
 }
diff --git app/code/core/Mage/Core/Controller/Request/Http.php app/code/core/Mage/Core/Controller/Request/Http.php
index d1720d93c93..d061c7a9a0c 100644
--- app/code/core/Mage/Core/Controller/Request/Http.php
+++ app/code/core/Mage/Core/Controller/Request/Http.php
@@ -262,9 +262,9 @@ class Mage_Core_Controller_Request_Http extends Zend_Controller_Request_Http
         return $path;
     }
 
-    public function getBaseUrl()
+    public function getBaseUrl($raw = false)
     {
-        $url = parent::getBaseUrl();
+        $url = parent::getBaseUrl($raw);
         $url = str_replace('\\', '/', $url);
         return $url;
     }
diff --git app/code/core/Mage/Core/Helper/Data.php app/code/core/Mage/Core/Helper/Data.php
index 62a3209d078..c75fb06f7f4 100644
--- app/code/core/Mage/Core/Helper/Data.php
+++ app/code/core/Mage/Core/Helper/Data.php
@@ -253,11 +253,41 @@ class Mage_Core_Helper_Data extends Mage_Core_Helper_Abstract
         return $this->getEncryptor()->getHash($password, $salt);
     }
 
+    /**
+     *  Generate password hash for user
+     *
+     * @param string $password
+     * @param mixed $salt
+     * @return string
+     */
+    public function getHashPassword($password, $salt = false)
+    {
+        $encryptionModel = $this->getEncryptor();
+        $latestVersionHash = $this->getVersionHash($encryptionModel);
+        if ($latestVersionHash == $encryptionModel::HASH_VERSION_SHA512) {
+            return $this->getEncryptor()->getHashPassword($password, $salt);
+        }
+        return $this->getEncryptor()->getHashPassword($password, Mage_Admin_Model_User::HASH_SALT_EMPTY);
+    }
+
     public function validateHash($password, $hash)
     {
         return $this->getEncryptor()->validateHash($password, $hash);
     }
 
+    /**
+     * Get encryption method depending on the presence of the function - password_hash.
+     *
+     * @param Mage_Core_Model_Encryption $encryptionModel
+     * @return int
+     */
+    public function getVersionHash(Mage_Core_Model_Encryption $encryptionModel)
+    {
+        return function_exists('password_hash')
+            ? $encryptionModel::HASH_VERSION_LATEST
+            : $encryptionModel::HASH_VERSION_SHA512;
+    }
+
     /**
      * Retrieve store identifier
      *
diff --git app/code/core/Mage/Core/Helper/String.php app/code/core/Mage/Core/Helper/String.php
index edffcf2b36d..1cd4bc2ccdd 100644
--- app/code/core/Mage/Core/Helper/String.php
+++ app/code/core/Mage/Core/Helper/String.php
@@ -318,4 +318,36 @@ class Mage_Core_Helper_String extends Mage_Core_Helper_Abstract
 
         return $sort;
     }
+
+    /**
+     * Detect serialization of data Array or Object
+     *
+     * @param mixed $data
+     * @return bool
+     */
+    public function isSerializedArrayOrObject($data)
+    {
+        $pattern =
+            '/^a:\d+:\{(i:\d+;|s:\d+:\".+\";|N;|O:\d+:\"\w+\":\d+:\{\w:\d+:)+|^O:\d+:\"\w+\":\d+:\{(s:\d+:\"|i:\d+;)/';
+        return is_string($data) && preg_match($pattern, $data);
+    }
+
+    /**
+     * Validate is Serialized Data Object in string
+     *
+     * @param string $str
+     * @return bool
+     */
+    public function validateSerializedObject($str)
+    {
+        if ($this->isSerializedArrayOrObject($str)) {
+            try {
+                $this->unserialize($str);
+            } catch (Exception $e) {
+                return false;
+            }
+        }
+
+        return true;
+    }
 }
diff --git app/code/core/Mage/Core/Model/App.php app/code/core/Mage/Core/Model/App.php
index f4043633312..c594b2e8280 100644
--- app/code/core/Mage/Core/Model/App.php
+++ app/code/core/Mage/Core/Model/App.php
@@ -67,6 +67,22 @@ class Mage_Core_Model_App
      */
     const ADMIN_STORE_ID = 0;
 
+    /**
+     * The absolute minimum of password length for all types of passwords
+     *
+     * With changing this value also need to change:
+     * 1. in `js/prototype/validation.js` declarations `var minLength = 7;` in two places;
+     * 2. in `app/code/core/Mage/Customer/etc/system.xml`
+     *    comments for fields `min_password_length` and `min_admin_password_length`
+     *    `<comment>Please enter a number 7 or greater in this field.</comment>`;
+     * 3. in `app/code/core/Mage/Customer/etc/config.xml` value `<min_password_length>7</min_password_length>`
+     *    and, maybe, value `<min_admin_password_length>14</min_admin_password_length>`
+     *    (if the absolute minimum of password length is higher then this value);
+     * 4. maybe, the value of deprecated `const MIN_PASSWORD_LENGTH` in `app/code/core/Mage/Admin/Model/User.php`,
+     *    (if the absolute minimum of password length is higher then this value).
+     */
+    const ABSOLUTE_MIN_PASSWORD_LENGTH = 7;
+
     /**
      * Application loaded areas array
      *
diff --git app/code/core/Mage/Core/Model/Encryption.php app/code/core/Mage/Core/Model/Encryption.php
index 2e40026e473..297808f4b98 100644
--- app/code/core/Mage/Core/Model/Encryption.php
+++ app/code/core/Mage/Core/Model/Encryption.php
@@ -33,6 +33,14 @@
  */
 class Mage_Core_Model_Encryption
 {
+    const HASH_VERSION_MD5    = 0;
+    const HASH_VERSION_SHA512 = 2;
+
+    /**
+     * Encryption method bcrypt
+     */
+    const HASH_VERSION_LATEST = 3;
+
     /**
      * @var Varien_Crypt_Mcrypt
      */
@@ -74,14 +82,37 @@ class Mage_Core_Model_Encryption
         return $salt === false ? $this->hash($password) : $this->hash($salt . $password) . ':' . $salt;
     }
 
+    /**
+     * Generate hash for customer password
+     *
+     * @param string $password
+     * @param mixed $salt
+     * @return string
+     */
+    public function getHashPassword($password, $salt = null)
+    {
+        if (is_integer($salt)) {
+            $salt = $this->_helper->getRandomString($salt);
+        }
+        return (bool) $salt
+            ? $this->hash($salt . $password, $this->_helper->getVersionHash($this)) . ':' . $salt
+            : $this->hash($password, $this->_helper->getVersionHash($this));
+    }
+
     /**
      * Hash a string
      *
      * @param string $data
-     * @return string
+     * @param int $version
+     * @return bool|string
      */
-    public function hash($data)
+    public function hash($data, $version = self::HASH_VERSION_MD5)
     {
+        if (self::HASH_VERSION_LATEST === $version && $version === $this->_helper->getVersionHash($this)) {
+            return password_hash($data, PASSWORD_DEFAULT);
+        } elseif (self::HASH_VERSION_SHA512 == $version) {
+            return hash('sha512', $data);
+        }
         return md5($data);
     }
 
@@ -95,14 +126,31 @@ class Mage_Core_Model_Encryption
      */
     public function validateHash($password, $hash)
     {
-        $hashArr = explode(':', $hash);
-        switch (count($hashArr)) {
-            case 1:
-                return hash_equals($this->hash($password), $hash);
-            case 2:
-                return hash_equals($this->hash($hashArr[1] . $password),  $hashArr[0]);
+        return $this->validateHashByVersion($password, $hash, self::HASH_VERSION_LATEST)
+            || $this->validateHashByVersion($password, $hash, self::HASH_VERSION_SHA512)
+            || $this->validateHashByVersion($password, $hash, self::HASH_VERSION_MD5);
+    }
+
+    /**
+     * Validate hash by specified version
+     *
+     * @param string $password
+     * @param string $hash
+     * @param int $version
+     * @return bool
+     */
+    public function validateHashByVersion($password, $hash, $version = self::HASH_VERSION_MD5)
+    {
+        if ($version == self::HASH_VERSION_LATEST && $version == $this->_helper->getVersionHash($this)) {
+            return password_verify($password, $hash);
+        }
+        // look for salt
+        $hashArr = explode(':', $hash, 2);
+        if (1 === count($hashArr)) {
+            return hash_equals($this->hash($password, $version), $hash);
         }
-        Mage::throwException('Invalid hash.');
+        list($hash, $salt) = $hashArr;
+        return hash_equals($this->hash($salt . $password, $version), $hash);
     }
 
     /**
diff --git app/code/core/Mage/Core/Model/File/Uploader.php app/code/core/Mage/Core/Model/File/Uploader.php
index 626a9c12029..4cb5a492ced 100644
--- app/code/core/Mage/Core/Model/File/Uploader.php
+++ app/code/core/Mage/Core/Model/File/Uploader.php
@@ -41,6 +41,13 @@ class Mage_Core_Model_File_Uploader extends Varien_File_Uploader
      */
     protected $_skipDbProcessing = false;
 
+    /**
+     * Max file name length
+     *
+     * @var int
+     */
+    protected $_fileNameMaxLength = 200;
+
     /**
      * Save file to storage
      *
@@ -99,4 +106,25 @@ class Mage_Core_Model_File_Uploader extends Varien_File_Uploader
 
         return parent::checkAllowedExtension($extension);
     }
+
+    /**
+     * Used to save uploaded file into destination folder with
+     * original or new file name (if specified).
+     * Added file name length validation.
+     *
+     * @param string $destinationFolder
+     * @param string|null $newFileName
+     * @return bool|void
+     * @throws Exception
+     */
+    public function save($destinationFolder, $newFileName = null)
+    {
+        $fileName = isset($newFileName) ? $newFileName : $this->_file['name'];
+        if (strlen($fileName) > $this->_fileNameMaxLength) {
+            throw new Exception(
+                Mage::helper('core')->__("File name is too long. Maximum length is %s.", $this->_fileNameMaxLength)
+            );
+        }
+        return parent::save($destinationFolder, $newFileName);
+    }
 }
diff --git app/code/core/Mage/Core/Model/Input/Filter/MaliciousCode.php app/code/core/Mage/Core/Model/Input/Filter/MaliciousCode.php
index 6946befbea2..3d70b609641 100644
--- app/code/core/Mage/Core/Model/Input/Filter/MaliciousCode.php
+++ app/code/core/Mage/Core/Model/Input/Filter/MaliciousCode.php
@@ -50,11 +50,13 @@ class Mage_Core_Model_Input_Filter_MaliciousCode implements Zend_Filter_Interfac
         //js in the style attribute
         '/style=[^<]*((expression\s*?\([^<]*?\))|(behavior\s*:))[^<]*(?=\>)/Uis',
         //js attributes
-        '/(ondblclick|onclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|onload|onunload|onerror)\s*=[^>]*(?=\>)/Uis',
+        '/(ondblclick|onclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|onload|onunload|onerror|onanimationstart)\s*=[^>]*(?=\>)/Uis',
         //tags
         '/<\/?(script|meta|link|frame|iframe).*>/Uis',
         //base64 usage
         '/src\s*=[^<]*base64[^<]*(?=\>)/Uis',
+        //data attribute
+        '/(data(\\\\x3a|:|%3A)(.+?(?=")|.+?(?=\')))/is',
     );
 
     /**
@@ -99,4 +101,64 @@ class Mage_Core_Model_Input_Filter_MaliciousCode implements Zend_Filter_Interfac
         $this->_expressions = $expressions;
         return $this;
     }
+
+    /**
+     * The filter adds safe attributes to the link
+     *
+     * @param string $html
+     * @param bool $removeWrapper flag for remove wrapper tags: Doctype, html, body
+     * @return string
+     * @throws Mage_Core_Exception
+     */
+    public function linkFilter($html, $removeWrapper = true)
+    {
+        if (stristr($html, '<a ') === false) {
+            return $html;
+        }
+
+        $libXmlErrorsState = libxml_use_internal_errors(true);
+        $dom = $this->_initDOMDocument();
+        if (!$dom->loadHTML($html)) {
+            Mage::throwException(Mage::helper('core')->__('HTML filtration has failed.'));
+        }
+
+        $relAttributeDefaultItems = array('noopener', 'noreferrer');
+        /** @var DOMElement $linkItem */
+        foreach ($dom->getElementsByTagName('a') as $linkItem) {
+            $relAttributeItems = array();
+            $relAttributeCurrentValue = $linkItem->getAttribute('rel');
+            if (!empty($relAttributeCurrentValue)) {
+                $relAttributeItems = explode(' ', $relAttributeCurrentValue);
+            }
+            $relAttributeItems = array_unique(array_merge($relAttributeItems, $relAttributeDefaultItems));
+            $linkItem->setAttribute('rel', implode(' ', $relAttributeItems));
+            $linkItem->setAttribute('target', '_blank');
+        }
+
+        if (!$html = $dom->saveHTML()) {
+            Mage::throwException(Mage::helper('core')->__('HTML filtration has failed.'));
+        }
+
+        if ($removeWrapper) {
+            $html = preg_replace('/<(?:!DOCTYPE|\/?(?:html|body))[^>]*>\s*/i', '', $html);
+        }
+
+        libxml_use_internal_errors($libXmlErrorsState);
+
+        return $html;
+    }
+
+    /**
+     * Initialize built-in DOM parser instance
+     *
+     * @return DOMDocument
+     */
+    protected function _initDOMDocument()
+    {
+        $dom = new DOMDocument();
+        $dom->strictErrorChecking = false;
+        $dom->recover = false;
+
+        return $dom;
+    }
 }
diff --git app/code/core/Mage/Core/Model/Layout/Validator.php app/code/core/Mage/Core/Model/Layout/Validator.php
new file mode 100644
index 00000000000..089d2965eb8
--- /dev/null
+++ app/code/core/Mage/Core/Model/Layout/Validator.php
@@ -0,0 +1,258 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage
+ * @copyright Copyright (c) 2006-2019 Magento, Inc. (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+/**
+ * Validator for custom layout update
+ *
+ * Validator checked XML validation and protected expressions
+ *
+ * @category   Mage
+ * @package    Mage_Core
+ * @author     Magento Core Team <core@magentocommerce.com>
+ */
+class Mage_Core_Model_Layout_Validator extends Zend_Validate_Abstract
+{
+    const XML_PATH_LAYOUT_DISALLOWED_BLOCKS       = 'validators/custom_layout/disallowed_block';
+    const XML_INVALID                             = 'invalidXml';
+    const INVALID_TEMPLATE_PATH                   = 'invalidTemplatePath';
+    const INVALID_BLOCK_NAME                      = 'invalidBlockName';
+    const PROTECTED_ATTR_HELPER_IN_TAG_ACTION_VAR = 'protectedAttrHelperInActionVar';
+    const INVALID_XML_OBJECT_EXCEPTION            = 'invalidXmlObject';
+
+    /**
+     * The Varien SimpleXml object
+     *
+     * @var Varien_Simplexml_Element
+     */
+    protected $_value;
+
+    /**
+     * XPath expression for checking layout update
+     *
+     * @var array
+     */
+    protected $_disallowedXPathExpressions = array(
+        '*//template',
+        '*//@template',
+        '//*[@method=\'setTemplate\']',
+        '//*[@method=\'setDataUsingMethod\']//*[contains(translate(text(),
+        \'ABCDEFGHIJKLMNOPQRSTUVWXYZ\', \'abcdefghijklmnopqrstuvwxyz\'), \'template\')]/../*',
+    );
+
+    /**
+     * @var string
+     */
+    protected $_xpathBlockValidationExpression = '';
+
+    /**
+     * Disallowed template name
+     *
+     * @var array
+     */
+    protected $_disallowedBlock = array();
+
+    /**
+     * Protected expressions
+     *
+     * @var array
+     */
+    protected $_protectedExpressions = array(
+        self::PROTECTED_ATTR_HELPER_IN_TAG_ACTION_VAR => '//action/*[@helper]',
+    );
+
+    /**
+     * Construct
+     */
+    public function __construct()
+    {
+        $this->_initMessageTemplates();
+        $this->getDisallowedBlocks();
+    }
+
+    /**
+     * Initialize messages templates with translating
+     *
+     * @return Mage_Core_Model_Layout_Validator
+     */
+    protected function _initMessageTemplates()
+    {
+        if (!$this->_messageTemplates) {
+            $this->_messageTemplates = array(
+                self::PROTECTED_ATTR_HELPER_IN_TAG_ACTION_VAR =>
+                    Mage::helper('core')->__('Helper attributes should not be used in custom layout updates.'),
+                self::XML_INVALID => Mage::helper('core')->__('XML data is invalid.'),
+                self::INVALID_TEMPLATE_PATH => Mage::helper('core')->__(
+                    'Invalid template path used in layout update.'
+                ),
+                self::INVALID_BLOCK_NAME => Mage::helper('core')->__('Disallowed block name for frontend.'),
+                self::INVALID_XML_OBJECT_EXCEPTION =>
+                    Mage::helper('core')->__('XML object is not instance of "Varien_Simplexml_Element".'),
+            );
+        }
+        return $this;
+    }
+
+    /**
+     * @return array
+     */
+    public function getDisallowedBlocks()
+    {
+        if (!count($this->_disallowedBlock)) {
+            $disallowedBlockConfig = $this->_getDisallowedBlockConfigValue();
+            if (is_array($disallowedBlockConfig)) {
+                foreach ($disallowedBlockConfig as $blockName => $value) {
+                    $this->_disallowedBlock[] = $blockName;
+                }
+            }
+        }
+        return $this->_disallowedBlock;
+    }
+
+    /**
+     * @return mixed
+     */
+    protected function _getDisallowedBlockConfigValue()
+    {
+        return Mage::getStoreConfig(self::XML_PATH_LAYOUT_DISALLOWED_BLOCKS);
+    }
+
+    /**
+     * Returns true if and only if $value meets the validation requirements
+     *
+     * If $value fails validation, then this method returns false, and
+     * getMessages() will return an array of messages that explain why the
+     * validation failed.
+     *
+     * @throws Exception            Throw exception when xml object is not
+     *                              instance of Varien_Simplexml_Element
+     * @param Varien_Simplexml_Element|string $value
+     * @return bool
+     */
+    public function isValid($value)
+    {
+        if (is_string($value)) {
+            $value = trim($value);
+            try {
+                $value = new Varien_Simplexml_Element('<config>' . $value . '</config>');
+            } catch (Exception $e) {
+                $this->_error(self::XML_INVALID);
+                return false;
+            }
+        } elseif (!($value instanceof Varien_Simplexml_Element)) {
+            throw new Exception($this->_messageTemplates[self::INVALID_XML_OBJECT_EXCEPTION]);
+        }
+        if ($value->xpath($this->getXpathBlockValidationExpression())) {
+            $this->_error(self::INVALID_BLOCK_NAME);
+            return false;
+        }
+        // if layout update declare custom templates then validate their paths
+        if ($templatePaths = $value->xpath($this->getXpathValidationExpression())) {
+            try {
+                $this->validateTemplatePath($templatePaths);
+            } catch (Exception $e) {
+                $this->_error(self::INVALID_TEMPLATE_PATH);
+                return false;
+            }
+        }
+        $this->_setValue($value);
+
+        foreach ($this->_protectedExpressions as $key => $xpr) {
+            if ($this->_value->xpath($xpr)) {
+                $this->_error($key);
+                return false;
+            }
+        }
+        return true;
+    }
+
+    /**
+     * @return array
+     */
+    public function getProtectedExpressions()
+    {
+        return $this->_protectedExpressions;
+    }
+
+    /**
+     * Returns xPath for validate incorrect path to template
+     *
+     * @return string xPath for validate incorrect path to template
+     */
+    public function getXpathValidationExpression()
+    {
+        return implode(" | ", $this->_disallowedXPathExpressions);
+    }
+
+    /**
+     * @return array
+     */
+    public function getDisallowedXpathValidationExpression()
+    {
+        return $this->_disallowedXPathExpressions;
+    }
+
+    /**
+     * Returns xPath for validate incorrect block name
+     *
+     * @return string xPath for validate incorrect block name
+     */
+    public function getXpathBlockValidationExpression()
+    {
+        if (!$this->_xpathBlockValidationExpression) {
+            if (count($this->_disallowedBlock)) {
+                foreach ($this->_disallowedBlock as $key => $value) {
+                    $this->_xpathBlockValidationExpression .= $key > 0 ? " | " : '';
+                    $this->_xpathBlockValidationExpression .=
+                        "//block[translate(@type, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') = ";
+                    $this->_xpathBlockValidationExpression .=
+                        "translate('$value', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')]";
+                }
+            }
+        }
+        return $this->_xpathBlockValidationExpression;
+    }
+
+    /**
+     * Validate template path for preventing access to the directory above
+     * If template path value has "../"
+     *
+     * @throws Exception
+     *
+     * @param $templatePaths | array
+     */
+    public function validateTemplatePath(array $templatePaths)
+    {
+        /** @var $path Varien_Simplexml_Element */
+        foreach ($templatePaths as $path) {
+            if ($path->hasChildren()) {
+                $path = stripcslashes(trim((string) $path->children(), '"'));
+            }
+            if (strpos($path, '..' . DS) !== false) {
+                throw new Exception();
+            }
+        }
+    }
+}
diff --git app/code/core/Mage/Core/Model/Resource/File/Storage/Database.php app/code/core/Mage/Core/Model/Resource/File/Storage/Database.php
index d140bd71911..83bdb813491 100644
--- app/code/core/Mage/Core/Model/Resource/File/Storage/Database.php
+++ app/code/core/Mage/Core/Model/Resource/File/Storage/Database.php
@@ -71,7 +71,7 @@ class Mage_Core_Model_Resource_File_Storage_Database extends Mage_Core_Model_Res
                 'nullable' => false,
                 'default' => Varien_Db_Ddl_Table::TIMESTAMP_INIT
                 ), 'Upload Timestamp')
-            ->addColumn('filename', Varien_Db_Ddl_Table::TYPE_TEXT, 100, array(
+            ->addColumn('filename', Varien_Db_Ddl_Table::TYPE_TEXT, 255, array(
                 'nullable' => false
                 ), 'Filename')
             ->addColumn('directory_id', Varien_Db_Ddl_Table::TYPE_INTEGER, null, array(
diff --git app/code/core/Mage/Core/etc/config.xml app/code/core/Mage/Core/etc/config.xml
index 0f705f84393..9f040a7f87a 100644
--- app/code/core/Mage/Core/etc/config.xml
+++ app/code/core/Mage/Core/etc/config.xml
@@ -28,7 +28,7 @@
 <config>
     <modules>
         <Mage_Core>
-            <version>1.6.0.1.1.3</version>
+            <version>1.6.0.1.1.5</version>
         </Mage_Core>
     </modules>
     <global>
@@ -383,6 +383,7 @@
             <security>
                 <use_form_key>1</use_form_key>
                 <extensions_compatibility_mode>1</extensions_compatibility_mode>
+                <secure_system_configuration_save_disabled>0</secure_system_configuration_save_disabled>
             </security>
         </admin>
         <general>
@@ -439,6 +440,13 @@
                 <admin_user_create></admin_user_create>
             </additional_notification_emails>
         </general>
+        <validators>
+            <custom_layout>
+                <disallowed_block>
+                    <Mage_Core_Block_Template_Zend/>
+                </disallowed_block>
+            </custom_layout>
+        </validators>
     </default>
     <stores>
         <default>
diff --git app/code/core/Mage/Core/etc/system.xml app/code/core/Mage/Core/etc/system.xml
index 5b34438b1a0..aaa6f1ad639 100644
--- app/code/core/Mage/Core/etc/system.xml
+++ app/code/core/Mage/Core/etc/system.xml
@@ -119,6 +119,7 @@
                     <show_in_default>1</show_in_default>
                     <show_in_website>1</show_in_website>
                     <show_in_store>1</show_in_store>
+                    <dynamic_group>1</dynamic_group>
                 </modules_disable_output>
             </groups>
         </advanced>
diff --git app/code/core/Mage/Core/sql/core_setup/upgrade-1.6.0.1.1.3-1.6.0.1.1.4.php app/code/core/Mage/Core/sql/core_setup/upgrade-1.6.0.1.1.3-1.6.0.1.1.4.php
new file mode 100644
index 00000000000..f0b2f9ed3c6
--- /dev/null
+++ app/code/core/Mage/Core/sql/core_setup/upgrade-1.6.0.1.1.3-1.6.0.1.1.4.php
@@ -0,0 +1,35 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage
+ * @copyright Copyright (c) 2006-2019 Magento, Inc. (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+/* @var $installer Mage_Core_Model_Resource_Setup */
+$installer = $this;
+
+$installer->startSetup();
+$connection = $installer->getConnection();
+
+$connection->addColumn($installer->getTable('core_config_data'), 'updated_at', Varien_Db_Ddl_Table::TYPE_TIMESTAMP);
+
+$installer->endSetup();
diff --git app/code/core/Mage/Core/sql/core_setup/upgrade-1.6.0.1.1.4-1.6.0.1.1.5.php app/code/core/Mage/Core/sql/core_setup/upgrade-1.6.0.1.1.4-1.6.0.1.1.5.php
new file mode 100644
index 00000000000..fdd3d8a74f4
--- /dev/null
+++ app/code/core/Mage/Core/sql/core_setup/upgrade-1.6.0.1.1.4-1.6.0.1.1.5.php
@@ -0,0 +1,48 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage
+ * @copyright Copyright (c) 2006-2019 Magento, Inc. (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+/* @var $installer Mage_Core_Model_Resource_Setup */
+$installer = $this;
+$installer->startSetup();
+$table = $installer->getTable('core/file_storage');
+
+/**
+ * Change column
+ */
+if ($installer->getConnection()->isTableExists($table)) {
+    $installer->getConnection()->modifyColumn(
+        $table,
+        'filename',
+        array(
+            'type' => Varien_Db_Ddl_Table::TYPE_TEXT,
+            'length' => 255,
+            'nullable' => false,
+            'comment' => 'Filename',
+        )
+    );
+}
+
+$installer->endSetup();
diff --git app/code/core/Mage/Customer/Block/Address/Renderer/Default.php app/code/core/Mage/Customer/Block/Address/Renderer/Default.php
index 80df3684ae6..ebb2863d0e5 100644
--- app/code/core/Mage/Customer/Block/Address/Renderer/Default.php
+++ app/code/core/Mage/Customer/Block/Address/Renderer/Default.php
@@ -66,7 +66,13 @@ class Mage_Customer_Block_Address_Renderer_Default extends Mage_Core_Block_Abstr
     public function getFormat(Mage_Customer_Model_Address_Abstract $address=null)
     {
         $countryFormat = is_null($address) ? false : $address->getCountryModel()->getFormat($this->getType()->getCode());
-        $format = $countryFormat ? $countryFormat->getFormat() : $this->getType()->getDefaultFormat();
+        if ($countryFormat) {
+            $format = $countryFormat->getFormat();
+        } else {
+            $regExp = "/^[^()\n]*+(\((?>[^()\n]|(?1))*+\)[^()\n]*+)++$|^[^()]+?$/m";
+            preg_match_all($regExp, $this->getType()->getDefaultFormat(), $matches, PREG_SET_ORDER);
+            $format = count($matches) ? $this->_prepareAddressTemplateData($this->getType()->getDefaultFormat()) : null;
+        }
         return $format;
     }
 
@@ -128,9 +134,25 @@ class Mage_Customer_Block_Address_Renderer_Default extends Mage_Core_Block_Abstr
         }
 
         $formater->setVariables($data);
-
-        $format = !is_null($format) ? $format : $this->getFormat($address);
+        $format = !is_null($format) ? $format : $this->_prepareAddressTemplateData($this->getFormat($address));
 
         return $formater->filter($format);
     }
+
+    /**
+     * Get address template data without url and js code
+     * @param $data
+     * @return string
+     */
+    protected function _prepareAddressTemplateData($data)
+    {
+        $result = '';
+        if (is_string($data)) {
+            $urlRegExp = "@(https?://([-\w\.]+[-\w])+(:\d+)?(/([\w/_\.#-]*(\?\S+)?[^\.\s])?)?)@";
+            /** @var $maliciousCodeFilter Mage_Core_Model_Input_Filter_MaliciousCode */
+            $maliciousCodeFilter = Mage::getSingleton('core/input_filter_maliciousCode');
+            $result = preg_replace($urlRegExp, ' ', $maliciousCodeFilter->filter($data));
+        }
+        return $result;
+    }
 }
diff --git app/code/core/Mage/Customer/Block/Form/Register.php app/code/core/Mage/Customer/Block/Form/Register.php
index 1b7bc8ac728..66c4b279bde 100644
--- app/code/core/Mage/Customer/Block/Form/Register.php
+++ app/code/core/Mage/Customer/Block/Form/Register.php
@@ -161,4 +161,14 @@ class Mage_Customer_Block_Form_Register extends Mage_Directory_Block_Data
 
         return $this;
     }
+
+    /**
+     * Retrieve minimum length of customer password
+     *
+     * @return int
+     */
+    public function getMinPasswordLength()
+    {
+        return Mage::getModel('customer/customer')->getMinPasswordLength();
+    }
 }
diff --git app/code/core/Mage/Customer/Model/Customer.php app/code/core/Mage/Customer/Model/Customer.php
index 793aa07ea57..f50f303967c 100644
--- app/code/core/Mage/Customer/Model/Customer.php
+++ app/code/core/Mage/Customer/Model/Customer.php
@@ -48,8 +48,14 @@ class Mage_Customer_Model_Customer extends Mage_Core_Model_Abstract
 
     /**
      * Minimum Password Length
+     * @deprecated Use getMinPasswordLength() method instead
      */
-    const MINIMUM_PASSWORD_LENGTH = 6;
+    const MINIMUM_PASSWORD_LENGTH = Mage_Core_Model_App::ABSOLUTE_MIN_PASSWORD_LENGTH;
+
+    /**
+     * Configuration path for minimum length of password
+     */
+    const XML_PATH_MIN_PASSWORD_LENGTH = 'customer/password/min_password_length';
 
     /**
      * Maximum Password Length
@@ -338,7 +344,7 @@ class Mage_Customer_Model_Customer extends Mage_Core_Model_Abstract
      */
     public function hashPassword($password, $salt = null)
     {
-        return Mage::helper('core')->getHash($password, !is_null($salt) ? $salt : 2);
+        return Mage::helper('core')->getHashPassword(trim($password), (bool) $salt ? $salt : Mage_Admin_Model_User::HASH_SALT_LENGTH);
     }
 
     /**
@@ -349,6 +355,10 @@ class Mage_Customer_Model_Customer extends Mage_Core_Model_Abstract
      */
     public function generatePassword($length = 6)
     {
+        $minPasswordLength = $this->getMinPasswordLength();
+        if ($minPasswordLength > $length) {
+            $length = $minPasswordLength;
+        }
         return Mage::helper('core')->getRandomString($length);
     }
 
@@ -744,12 +754,10 @@ class Mage_Customer_Model_Customer extends Mage_Core_Model_Abstract
         if (!$this->getId() && !Zend_Validate::is($password , 'NotEmpty')) {
             $errors[] = $customerHelper->__('The password cannot be empty.');
         }
-        if (
-            strlen($password)
-            && !Zend_Validate::is($password, 'StringLength', array(self::MINIMUM_PASSWORD_LENGTH))
-        ) {
+        $minPasswordLength = $this->getMinPasswordLength();
+        if (strlen($password) && !Zend_Validate::is($password, 'StringLength', array($minPasswordLength))) {
             $errors[] = Mage::helper('customer')
-                ->__('The minimum password length is %s', self::MINIMUM_PASSWORD_LENGTH);
+                ->__('The minimum password length is %s', $minPasswordLength);
         }
         if (
             strlen($password)
@@ -1232,4 +1240,16 @@ class Mage_Customer_Model_Customer extends Mage_Core_Model_Abstract
         }
         return $defaultStoreId;
     }
+
+    /**
+     * Retrieve minimum length of password
+     *
+     * @return int
+     */
+    public function getMinPasswordLength()
+    {
+        $minLength = (int)Mage::getStoreConfig(self::XML_PATH_MIN_PASSWORD_LENGTH);
+        $absoluteMinLength = Mage_Core_Model_App::ABSOLUTE_MIN_PASSWORD_LENGTH;
+        return ($minLength < $absoluteMinLength) ? $absoluteMinLength : $minLength;
+    }
 }
diff --git app/code/core/Mage/Customer/Model/Customer/Attribute/Backend/Password.php app/code/core/Mage/Customer/Model/Customer/Attribute/Backend/Password.php
index 4163b188727..19a045f538d 100644
--- app/code/core/Mage/Customer/Model/Customer/Attribute/Backend/Password.php
+++ app/code/core/Mage/Customer/Model/Customer/Attribute/Backend/Password.php
@@ -43,8 +43,12 @@ class Mage_Customer_Model_Customer_Attribute_Backend_Password extends Mage_Eav_M
         $password = trim($object->getPassword());
         $len = Mage::helper('core/string')->strlen($password);
         if ($len) {
-             if ($len < 6) {
-                Mage::throwException(Mage::helper('customer')->__('The password must have at least 6 characters. Leading or trailing spaces will be ignored.'));
+            $minPasswordLength = Mage::getModel('customer/customer')->getMinPasswordLength();
+            if ($len < $minPasswordLength) {
+                Mage::throwException(Mage::helper('customer')->__(
+                    'The password must have at least %d characters. Leading or trailing spaces will be ignored.',
+                    $minPasswordLength
+                ));
             }
             $object->setPasswordHash($object->hashPassword($password));
         }
diff --git app/code/core/Mage/Customer/controllers/AccountController.php app/code/core/Mage/Customer/controllers/AccountController.php
index aca63ad4b9e..2b4b682cf94 100644
--- app/code/core/Mage/Customer/controllers/AccountController.php
+++ app/code/core/Mage/Customer/controllers/AccountController.php
@@ -787,14 +787,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
                     $newPass    = $this->getRequest()->getPost('password');
                     $confPass   = $this->getRequest()->getPost('confirmation');
 
-                    $oldPass = $this->_getSession()->getCustomer()->getPasswordHash();
-                    if ($this->_getHelper('core/string')->strpos($oldPass, ':')) {
-                        list($_salt, $salt) = explode(':', $oldPass);
-                    } else {
-                        $salt = false;
-                    }
-
-                    if ($customer->hashPassword($currPass, $salt) == $oldPass) {
+                    if ($customer->validatePassword($currPass)) {
                         if (strlen($newPass)) {
                             /**
                              * Set entered password and its confirmation - they
diff --git app/code/core/Mage/Customer/etc/config.xml app/code/core/Mage/Customer/etc/config.xml
index 0fc28bc1057..2c66e98b443 100644
--- app/code/core/Mage/Customer/etc/config.xml
+++ app/code/core/Mage/Customer/etc/config.xml
@@ -412,6 +412,7 @@
             <password>
                 <forgot_email_identity>support</forgot_email_identity>
                 <forgot_email_template>customer_password_forgot_email_template</forgot_email_template>
+                <min_password_length>7</min_password_length>
             </password>
             <address>
                 <street_lines>2</street_lines>
@@ -463,5 +464,10 @@ T: {{var telephone}}
                 <js_template>#{prefix} #{firstname} #{middlename} #{lastname} #{suffix}&lt;br/&gt;#{company}&lt;br/&gt;#{street0}&lt;br/&gt;#{street1}&lt;br/&gt;#{street2}&lt;br/&gt;#{street3}&lt;br/&gt;#{city}, #{region}, #{postcode}&lt;br/&gt;#{country_id}&lt;br/&gt;T: #{telephone}&lt;br/&gt;F: #{fax}</js_template>
             </address_templates>
         </customer>
+        <admin>
+            <security>
+                <min_admin_password_length>14</min_admin_password_length>
+            </security>
+        </admin>
     </default>
 </config>
diff --git app/code/core/Mage/Customer/etc/system.xml app/code/core/Mage/Customer/etc/system.xml
index e91377b1721..ea0ecececeb 100644
--- app/code/core/Mage/Customer/etc/system.xml
+++ app/code/core/Mage/Customer/etc/system.xml
@@ -188,6 +188,17 @@
                             <show_in_website>1</show_in_website>
                             <show_in_store>1</show_in_store>
                         </forgot_email_template>
+                        <min_password_length translate="label comment">
+                            <label>Minimum password length</label>
+                            <comment>Please enter a number 7 or greater in this field.</comment>
+                            <frontend_type>text</frontend_type>
+                            <validate>required-entry validate-digits validate-digits-range digits-range-7-</validate>
+                            <backend_model>adminhtml/system_config_backend_passwordlength</backend_model>
+                            <sort_order>60</sort_order>
+                            <show_in_default>1</show_in_default>
+                            <show_in_website>0</show_in_website>
+                            <show_in_store>0</show_in_store>
+                        </min_password_length>
                     </fields>
                 </password>
                 <address translate="label">
@@ -358,5 +369,24 @@
                 </address_templates>
             </groups>
         </customer>
+        <admin>
+            <groups>
+                <security>
+                    <fields>
+                        <min_admin_password_length translate="label comment">
+                            <label>Minimum admin password length</label>
+                            <comment>Please enter a number 7 or greater in this field.</comment>
+                            <frontend_type>text</frontend_type>
+                            <validate>required-entry validate-digits validate-digits-range digits-range-7-</validate>
+                            <backend_model>adminhtml/system_config_backend_passwordlength</backend_model>
+                            <sort_order>170</sort_order>
+                            <show_in_default>1</show_in_default>
+                            <show_in_website>0</show_in_website>
+                            <show_in_store>0</show_in_store>
+                        </min_admin_password_length>
+                    </fields>
+                </security>
+            </groups>
+        </admin>
     </sections>
 </config>
diff --git app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php
index 5c0d1f53e43..72b2fa2ed2b 100644
--- app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php
+++ app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php
@@ -55,9 +55,7 @@ abstract class Mage_Dataflow_Model_Convert_Container_Abstract
      */
     protected function isSerialized($data)
     {
-        $pattern =
-            '/^a:\d+:\{(i:\d+;|s:\d+:\".+\";|N;|O:\d+:\"\w+\":\d+:\{\w:\d+:)+|^O:\d+:\"\w+\":\d+:\{(s:\d+:\"|i:\d+;)/';
-        return (is_string($data) && preg_match($pattern, $data));
+        return Mage::helper('core/string')->isSerializedArrayOrObject($data);
     }
 
     public function getVar($key, $default=null)
diff --git app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php
index 8c901cc25ca..756de3acd1e 100644
--- app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php
+++ app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php
@@ -69,6 +69,7 @@ class Mage_Dataflow_Model_Convert_Parser_Csv extends Mage_Dataflow_Model_Convert
 
         if (!is_callable(array($adapter, $adapterMethod))) {
             $message = Mage::helper('dataflow')->__('Method "%s" not defined in adapter %s.', $adapterMethod, $adapterName);
+            $message = Mage::helper('dataflow')->escapeHtml($message);
             $this->addException($message, Mage_Dataflow_Model_Convert_Exception::FATAL);
             return $this;
         }
diff --git app/code/core/Mage/Dataflow/Model/Convert/Parser/Xml/Excel.php app/code/core/Mage/Dataflow/Model/Convert/Parser/Xml/Excel.php
index e9e460ad061..6bdf269143e 100644
--- app/code/core/Mage/Dataflow/Model/Convert/Parser/Xml/Excel.php
+++ app/code/core/Mage/Dataflow/Model/Convert/Parser/Xml/Excel.php
@@ -70,6 +70,7 @@ class Mage_Dataflow_Model_Convert_Parser_Xml_Excel extends Mage_Dataflow_Model_C
 
         if (!is_callable(array($adapter, $adapterMethod))) {
             $message = Mage::helper('dataflow')->__('Method "%s" was not defined in adapter %s.', $adapterMethod, $adapterName);
+            $message = Mage::helper('dataflow')->escapeHtml($message);
             $this->addException($message, Mage_Dataflow_Model_Convert_Exception::FATAL);
             return $this;
         }
diff --git app/code/core/Mage/Dataflow/Model/Profile.php app/code/core/Mage/Dataflow/Model/Profile.php
index 46c99986ba3..1a5e9db02b0 100644
--- app/code/core/Mage/Dataflow/Model/Profile.php
+++ app/code/core/Mage/Dataflow/Model/Profile.php
@@ -57,6 +57,20 @@ class Mage_Dataflow_Model_Profile extends Mage_Core_Model_Abstract
     const DEFAULT_EXPORT_PATH = 'var/export';
     const DEFAULT_EXPORT_FILENAME = 'export_';
 
+    /**
+     * Product table permanent attributes
+     *
+     * @var array
+     */
+    protected $_productTablePermanentAttributes = array('sku');
+
+    /**
+     * Customer table permanent attributes
+     *
+     * @var array
+     */
+    protected $_customerTablePermanentAttributes = array('email', 'website');
+
     protected function _construct()
     {
         $this->_init('dataflow/profile');
@@ -151,6 +165,9 @@ class Mage_Dataflow_Model_Profile extends Mage_Core_Model_Abstract
             ->setProfileId($this->getId())
             ->setActionCode($this->getOrigData('profile_id') ? 'update' : 'create')
             ->save();
+        $csvParser = new Varien_File_Csv();
+        $xmlParser = new DOMDocument();
+        $newUploadedFilenames = array();
 
         if (isset($_FILES['file_1']['tmp_name']) || isset($_FILES['file_2']['tmp_name'])
         || isset($_FILES['file_3']['tmp_name'])) {
@@ -160,9 +177,58 @@ class Mage_Dataflow_Model_Profile extends Mage_Core_Model_Abstract
                     $uploader->setAllowedExtensions(array('csv','xml'));
                     $path = Mage::app()->getConfig()->getTempVarDir() . '/import/';
                     $uploader->save($path);
-                    if ($uploadFile = $uploader->getUploadedFileName()) {
+                    $uploadFile = $uploader->getUploadedFileName();
+
+                    if ($_FILES['file_' . ($index + 1)]['type'] == "text/csv") {
+                        $fileData = $csvParser->getData($path . $uploadFile);
+                        $fileData = array_shift($fileData);
+                    } else {
+                        try {
+                            $xmlParser->loadXML(file_get_contents($path . $uploadFile));
+                            $cells = $this->getNode($xmlParser, 'Worksheet')->item(0);
+                            $cells = $this->getNode($cells, 'Row')->item(0);
+                            $cells = $this->getNode($cells, 'Cell');
+                            $fileData = array();
+                            foreach ($cells as $cell) {
+                                $fileData[] = $this->getNode($cell, 'Data')->item(0)->nodeValue;
+                            }
+                        } catch (Exception $e) {
+                            foreach ($newUploadedFilenames as $k => $v) {
+                                unlink($path . $v);
+                            }
+                            unlink($path . $uploadFile);
+                            Mage::throwException(
+                                Mage::helper('Dataflow')->__(
+                                    'Upload failed. Wrong data format in file: %s.',
+                                    $uploadFile
+                                )
+                            );
+                        }
+                    }
+
+                    if ($this->_data['entity_type'] == 'customer') {
+                        $attributes = $this->_customerTablePermanentAttributes;
+                    } else {
+                        $attributes = $this->_productTablePermanentAttributes;
+                    }
+                    $colsAbsent = array_diff($attributes, $fileData);
+                    if ($colsAbsent) {
+                        foreach ($newUploadedFilenames as $k => $v) {
+                            unlink($path . $v);
+                        }
+                        unlink($path . $uploadFile);
+                        Mage::throwException(
+                            Mage::helper('Dataflow')->__(
+                                'Upload failed. Can not find required columns: %s in file %s.',
+                                implode(', ', $colsAbsent),
+                                $uploadFile
+                            )
+                        );
+                    }
+                    if ($uploadFile) {
                         $newFilename = 'import-' . date('YmdHis') . '-' . ($index+1) . '_' . $uploadFile;
                         rename($path . $uploadFile, $path . $newFilename);
+                        $newUploadedFilenames[] = $newFilename;
                     }
                 }
                 //BOM deleting for UTF files
@@ -431,4 +497,20 @@ echo "<xmp>" . $xml . "</xmp>";
 die;*/
         return $this;
     }
+
+    /**
+     * Get node from xml object
+     *
+     * @param object $xmlObject
+     * @param string $nodeName
+     * @return object
+     * @throws Exception
+     */
+    protected function getNode($xmlObject, $nodeName)
+    {
+        if ($xmlObject != null) {
+            return $xmlObject->getElementsByTagName($nodeName);
+        }
+        Mage::throwException(Mage::helper('Dataflow')->__('Invalid node.'));
+    }
 }
diff --git app/code/core/Mage/Eav/Model/Entity/Attribute/Backend/Abstract.php app/code/core/Mage/Eav/Model/Entity/Attribute/Backend/Abstract.php
index 86d8d1019b3..b41765c9527 100644
--- app/code/core/Mage/Eav/Model/Entity/Attribute/Backend/Abstract.php
+++ app/code/core/Mage/Eav/Model/Entity/Attribute/Backend/Abstract.php
@@ -206,6 +206,15 @@ abstract class Mage_Eav_Model_Entity_Attribute_Backend_Abstract implements Mage_
             return false;
         }
 
+        //Validate serialized data
+        if (!Mage::helper('core/string')->validateSerializedObject($value)) {
+            $label = $this->getAttribute()->getFrontend()->getLabel();
+            throw Mage::exception(
+                'Mage_Eav',
+                Mage::helper('eav')->__('The value of attribute "%s" contains invalid data.', $label)
+            );
+        }
+
         if ($this->getAttribute()->getIsUnique()
             && !$this->getAttribute()->getIsRequired()
             && ($value == '' || $this->getAttribute()->isValueEmpty($value)))
diff --git app/code/core/Mage/ImportExport/Model/Import/Adapter/Abstract.php app/code/core/Mage/ImportExport/Model/Import/Adapter/Abstract.php
index 4ec7c4c8afb..449fd5e532d 100644
--- app/code/core/Mage/ImportExport/Model/Import/Adapter/Abstract.php
+++ app/code/core/Mage/ImportExport/Model/Import/Adapter/Abstract.php
@@ -174,4 +174,14 @@ abstract class Mage_ImportExport_Model_Import_Adapter_Abstract implements Seekab
     {
         return $this;
     }
+
+    /**
+     * Get the source path
+     *
+     * @return string
+     */
+    public function getSource()
+    {
+        return $this->_source;
+    }
 }
diff --git app/code/core/Mage/ImportExport/Model/Import/Entity/Abstract.php app/code/core/Mage/ImportExport/Model/Import/Entity/Abstract.php
index c297f126cf9..270df43a809 100644
--- app/code/core/Mage/ImportExport/Model/Import/Entity/Abstract.php
+++ app/code/core/Mage/ImportExport/Model/Import/Entity/Abstract.php
@@ -666,6 +666,7 @@ abstract class Mage_ImportExport_Model_Import_Entity_Abstract
         if (!$this->_dataValidated) {
             // does all permanent columns exists?
             if (($colsAbsent = array_diff($this->_permanentAttributes, $this->_getSource()->getColNames()))) {
+                file_put_contents($this->_getSource()->getSource(), "");
                 Mage::throwException(
                     Mage::helper('importexport')->__('Can not find required columns: %s', implode(', ', $colsAbsent))
                 );
diff --git app/code/core/Mage/Install/Block/Admin.php app/code/core/Mage/Install/Block/Admin.php
index d1c71607058..ad4efc5ad3c 100644
--- app/code/core/Mage/Install/Block/Admin.php
+++ app/code/core/Mage/Install/Block/Admin.php
@@ -51,4 +51,14 @@ class Mage_Install_Block_Admin extends Mage_Install_Block_Abstract
         }
         return $data;
     }
+
+    /**
+     * Retrieve minimum length of admin password
+     *
+     * @return int
+     */
+    public function getMinAdminPasswordLength()
+    {
+        return Mage::getModel('admin/user')->getMinAdminPasswordLength();
+    }
 }
diff --git app/code/core/Mage/Install/etc/config.xml app/code/core/Mage/Install/etc/config.xml
index 87244b60708..7de289bbeaf 100644
--- app/code/core/Mage/Install/etc/config.xml
+++ app/code/core/Mage/Install/etc/config.xml
@@ -57,6 +57,13 @@
                 </install>
             </routers>
         </web>
+        <validators>
+            <custom_layout>
+                <disallowed_block>
+                    <Mage_Install_Block_End/>
+                </disallowed_block>
+            </custom_layout>
+        </validators>
     </default>
     <stores>
         <default>
diff --git app/code/core/Mage/Review/controllers/ProductController.php app/code/core/Mage/Review/controllers/ProductController.php
index 9fa08100e27..39c92da9735 100644
--- app/code/core/Mage/Review/controllers/ProductController.php
+++ app/code/core/Mage/Review/controllers/ProductController.php
@@ -298,7 +298,17 @@ class Mage_Review_ProductController extends Mage_Core_Controller_Front_Action
             $this->getLayout()->helper('page/layout')
                 ->applyTemplate($product->getPageLayout());
         }
-        $update->addUpdate($product->getCustomLayoutUpdate());
+        $customLayout = $product->getCustomLayoutUpdate();
+        if ($customLayout) {
+            try {
+                if (!Mage::getModel('core/layout_validator')->isValid($customLayout)) {
+                    $customLayout = '';
+                }
+            } catch (Exception $e) {
+                $customLayout = '';
+            }
+        }
+        $update->addUpdate($customLayout);
         $this->generateLayoutXml()->generateLayoutBlocks();
     }
 
diff --git app/code/core/Mage/Rss/etc/config.xml app/code/core/Mage/Rss/etc/config.xml
index 54dffacbccb..96ad1eb73e1 100644
--- app/code/core/Mage/Rss/etc/config.xml
+++ app/code/core/Mage/Rss/etc/config.xml
@@ -119,4 +119,13 @@
             </updates>
         </layout>
     </frontend>
+    <default>
+        <validators>
+            <custom_layout>
+                <disallowed_block>
+                    <Mage_Rss_Block_Order_New/>
+                </disallowed_block>
+            </custom_layout>
+        </validators>
+    </default>
 </config>
diff --git app/code/core/Mage/Widget/controllers/Adminhtml/Widget/InstanceController.php app/code/core/Mage/Widget/controllers/Adminhtml/Widget/InstanceController.php
index 092d74437d3..1ca324294ea 100644
--- app/code/core/Mage/Widget/controllers/Adminhtml/Widget/InstanceController.php
+++ app/code/core/Mage/Widget/controllers/Adminhtml/Widget/InstanceController.php
@@ -281,6 +281,17 @@ class Mage_Widget_Adminhtml_Widget_InstanceController extends Mage_Adminhtml_Con
         $this->getResponse()->setBody($templateChooser->toHtml());
     }
 
+    /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions('delete');
+        return parent::preDispatch();
+    }
+
     /**
      * Check is allowed access to action
      *
diff --git app/code/core/Mage/Wishlist/Block/Abstract.php app/code/core/Mage/Wishlist/Block/Abstract.php
index a3f0dcc6561..e462fe784e6 100644
--- app/code/core/Mage/Wishlist/Block/Abstract.php
+++ app/code/core/Mage/Wishlist/Block/Abstract.php
@@ -164,7 +164,7 @@ abstract class Mage_Wishlist_Block_Abstract extends Mage_Catalog_Block_Product_A
      */
     public function getItemRemoveUrl($product)
     {
-        return $this->_getHelper()->getRemoveUrl($product);
+        return $this->getItemRemoveUrlCustom($product);
     }
 
     /**
@@ -175,7 +175,7 @@ abstract class Mage_Wishlist_Block_Abstract extends Mage_Catalog_Block_Product_A
      */
     public function getItemAddToCartUrl($item)
     {
-        return $this->_getHelper()->getAddToCartUrl($item);
+        return $this->getItemAddToCartUrlCustom($item);
     }
 
     /**
@@ -197,7 +197,7 @@ abstract class Mage_Wishlist_Block_Abstract extends Mage_Catalog_Block_Product_A
      */
     public function getAddToWishlistUrl($product)
     {
-        return $this->_getHelper()->getAddUrl($product);
+        return $this->getAddToWishlistUrlCustom($product);
     }
 
      /**
@@ -402,4 +402,49 @@ abstract class Mage_Wishlist_Block_Abstract extends Mage_Catalog_Block_Product_A
         }
         return parent::getProductUrl($product, $additional);
     }
+
+    /**
+     * Retrieve URL for adding Product to wishlist with or without Form Key
+     *
+     * @param Mage_Catalog_Model_Product $product
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function getAddToWishlistUrlCustom($product, $addFormKey = true)
+    {
+        if (!$addFormKey) {
+            return $this->_getHelper()->getAddUrlWithCustomParams($product, array(), false);
+        }
+        return $this->_getHelper()->getAddUrl($product);
+    }
+
+    /**
+     * Retrieve URL for Removing item from wishlist with or without Form Key
+     *
+     * @param Mage_Catalog_Model_Product|Mage_Wishlist_Model_Item $item
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function getItemRemoveUrlCustom($item, $addFormKey = true)
+    {
+        if (!$addFormKey) {
+            return $this->_getHelper()->getRemoveUrlCustom($item, false);
+        }
+        return $this->_getHelper()->getRemoveUrl($item);
+    }
+
+    /**
+     * Retrieve Add Item to shopping cart URL with or without Form Key
+     *
+     * @param string|Mage_Catalog_Model_Product|Mage_Wishlist_Model_Item $item
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function getItemAddToCartUrlCustom($item, $addFormKey = true)
+    {
+        if (!$addFormKey) {
+            return $this->_getHelper()->getAddToCartUrlCustom($item, false);
+        }
+        return $this->_getHelper()->getAddToCartUrl($item);
+    }
 }
diff --git app/code/core/Mage/Wishlist/Block/Item/Configure.php app/code/core/Mage/Wishlist/Block/Item/Configure.php
index 50fe5b274f8..7f19501605e 100644
--- app/code/core/Mage/Wishlist/Block/Item/Configure.php
+++ app/code/core/Mage/Wishlist/Block/Item/Configure.php
@@ -65,7 +65,9 @@ class Mage_Wishlist_Block_Item_Configure extends Mage_Core_Block_Template
         $block = $this->getLayout()->getBlock('product.info');
         if ($block) {
             $url = Mage::helper('wishlist')->getAddToCartUrl($this->getWishlistItem());
+            $postUrl = Mage::helper('wishlist')->getAddToCartUrlCustom($this->getWishlistItem(), false);
             $block->setCustomAddToCartUrl($url);
+            $block->setCustomAddToCartPostUrl($postUrl);
         }
 
         return parent::_prepareLayout();
diff --git app/code/core/Mage/Wishlist/Block/Share/Email/Items.php app/code/core/Mage/Wishlist/Block/Share/Email/Items.php
index fb373e3bb63..b9b84da0372 100644
--- app/code/core/Mage/Wishlist/Block/Share/Email/Items.php
+++ app/code/core/Mage/Wishlist/Block/Share/Email/Items.php
@@ -65,9 +65,22 @@ class Mage_Wishlist_Block_Share_Email_Items extends Mage_Wishlist_Block_Abstract
      * @return string
      */
     public function getAddToCartUrl($product, $additional = array())
+    {
+        return $this->getAddToCartUrlCustom($product, $additional);
+    }
+
+    /**
+     * Retrieve URL for add product to shopping cart with or without Form Key
+     *
+     * @param Mage_Catalog_Model_Product $product
+     * @param array $additional
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function getAddToCartUrlCustom($product, $additional = array(), $addFormKey = true)
     {
         $additional['nocookie'] = 1;
         $additional['_store_to_url'] = true;
-        return parent::getAddToCartUrl($product, $additional);
+        return parent::getAddToCartUrlCustom($product, $additional, $addFormKey);
     }
 }
diff --git app/code/core/Mage/Wishlist/Helper/Data.php app/code/core/Mage/Wishlist/Helper/Data.php
index 6be26754672..32c71df7c58 100644
--- app/code/core/Mage/Wishlist/Helper/Data.php
+++ app/code/core/Mage/Wishlist/Helper/Data.php
@@ -225,12 +225,7 @@ class Mage_Wishlist_Helper_Data extends Mage_Core_Helper_Abstract
      */
     public function getRemoveUrl($item)
     {
-        return $this->_getUrl('wishlist/index/remove',
-            array(
-                'item' => $item->getWishlistItemId(),
-                Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey()
-            )
-        );
+        return $this->getRemoveUrlCustom($item);
     }
 
     /**
@@ -290,20 +285,7 @@ class Mage_Wishlist_Helper_Data extends Mage_Core_Helper_Abstract
      */
     public function getAddUrlWithParams($item, array $params = array())
     {
-        $productId = null;
-        if ($item instanceof Mage_Catalog_Model_Product) {
-            $productId = $item->getEntityId();
-        }
-        if ($item instanceof Mage_Wishlist_Model_Item) {
-            $productId = $item->getProductId();
-        }
-
-        if (!$productId) {
-            return false;
-        }
-        $params['product'] = $productId;
-        $params[Mage_Core_Model_Url::FORM_KEY] = $this->_getSingletonModel('core/session')->getFormKey();
-        return $this->_getUrlStore($item)->getUrl('wishlist/index/add', $params);
+        return $this->getAddUrlWithCustomParams($item, $params);
     }
 
     /**
@@ -314,20 +296,7 @@ class Mage_Wishlist_Helper_Data extends Mage_Core_Helper_Abstract
      */
     public function getAddToCartUrl($item)
     {
-        $continueUrl  = $this->_getHelperInstance('core')->urlEncode(
-            $this->_getUrl('*/*/*', array(
-                '_current'      => true,
-                '_use_rewrite'  => true,
-                '_store_to_url' => true,
-            ))
-        );
-        $params = array(
-            'item' => is_string($item) ? $item : $item->getWishlistItemId(),
-            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $continueUrl,
-            Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey()
-        );
-
-        return $this->_getUrlStore($item)->getUrl('wishlist/index/cart', $params);
+        return $this->getAddToCartUrlCustom($item);
     }
 
     /**
@@ -500,4 +469,78 @@ class Mage_Wishlist_Helper_Data extends Mage_Core_Helper_Abstract
         Mage::dispatchEvent('wishlist_items_renewed');
         return $this;
     }
+
+    /**
+     * Retrieve url for adding product to wishlist with params with or without Form Key
+     *
+     * @param Mage_Catalog_Model_Product|Mage_Wishlist_Model_Item $item
+     * @param array $params
+     * @param bool $addFormKey
+     * @return string|bool
+     */
+    public function getAddUrlWithCustomParams($item, array $params = array(), $addFormKey = true)
+    {
+        $productId = null;
+        if ($item instanceof Mage_Catalog_Model_Product) {
+            $productId = $item->getEntityId();
+        }
+        if ($item instanceof Mage_Wishlist_Model_Item) {
+            $productId = $item->getProductId();
+        }
+
+        if ($productId) {
+            $params['product'] = $productId;
+            if ($addFormKey) {
+                $params[Mage_Core_Model_Url::FORM_KEY] = $this->_getSingletonModel('core/session')->getFormKey();
+            }
+            return $this->_getUrlStore($item)->getUrl('wishlist/index/add', $params);
+        }
+
+        return false;
+    }
+
+    /**
+     * Retrieve URL for removing item from wishlist with params with or without Form Key
+     *
+     * @param Mage_Catalog_Model_Product|Mage_Wishlist_Model_Item $item
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function getRemoveUrlCustom($item, $addFormKey = true)
+    {
+        $params = array(
+            'item' => $item->getWishlistItemId()
+        );
+        if ($addFormKey) {
+            $params[Mage_Core_Model_Url::FORM_KEY] = $this->_getSingletonModel('core/session')->getFormKey();
+        }
+
+        return $this->_getUrl('wishlist/index/remove', $params);
+    }
+
+    /**
+     * Retrieve URL for adding item to shopping cart with or without Form Key
+     *
+     * @param string|Mage_Catalog_Model_Product|Mage_Wishlist_Model_Item $item
+     * @param bool $addFormKey
+     * @return  string
+     */
+    public function getAddToCartUrlCustom($item, $addFormKey = true)
+    {
+        $continueUrl  = $this->_getHelperInstance('core')->urlEncode(
+            $this->_getUrl('*/*/*', array(
+                '_current'      => true,
+                '_use_rewrite'  => true,
+                '_store_to_url' => true,
+            ))
+        );
+        $params = array(
+            'item' => is_string($item) ? $item : $item->getWishlistItemId(),
+            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $continueUrl,
+        );
+        if ($addFormKey) {
+            $params[Mage_Core_Model_Url::FORM_KEY] = $this->_getSingletonModel('core/session')->getFormKey();
+        }
+        return $this->_getUrlStore($item)->getUrl('wishlist/index/cart', $params);
+    }
 }
diff --git app/design/frontend/base/default/template/catalog/product/list.phtml app/design/frontend/base/default/template/catalog/product/list.phtml
index 76371a393d4..6b11b9e7e11 100644
--- app/design/frontend/base/default/template/catalog/product/list.phtml
+++ app/design/frontend/base/default/template/catalog/product/list.phtml
@@ -34,6 +34,7 @@
 <?php
     $_productCollection=$this->getLoadedProductCollection();
     $_helper = $this->helper('catalog/output');
+    $_params = $this->escapeHtml(json_encode(array('form_key' => $this->getFormKey())));
 ?>
 <?php if(!$_productCollection->count()): ?>
 <p class="note-msg"><?php echo $this->__('There are no products matching the selection.') ?></p>
@@ -68,10 +69,26 @@
                     </div>
                     <ul class="add-to-links">
                         <?php if ($this->helper('wishlist')->isAllow()) : ?>
-                            <li><a href="<?php echo $this->helper('wishlist')->getAddUrl($_product) ?>" class="link-wishlist"><?php echo $this->__('Add to Wishlist') ?></a></li>
+                            <?php $_wishlistUrl = $this->helper('wishlist')->getAddUrlWithCustomParams($_product, array(), false); ?>
+                            <li>
+                                <a href="#"
+                                   data-url="<?php echo $_wishlistUrl ?>"
+                                   data-params="<?php echo $_params ?>"
+                                   class="link-wishlist"
+                                   onclick="customFormSubmit('<?php echo $_wishlistUrl ?>', '<?php echo $_params ?>', 'post')">
+                                    <?php echo $this->__('Add to Wishlist') ?>
+                                </a>
+                            </li>
                         <?php endif; ?>
-                        <?php if($_compareUrl=$this->getAddToCompareUrl($_product)): ?>
-                            <li><span class="separator">|</span> <a href="<?php echo $_compareUrl ?>" class="link-compare"><?php echo $this->__('Add to Compare') ?></a></li>
+                        <?php if ($_compareUrl = $this->getAddToCompareUrlCustom($_product, false)) : ?>
+                            <li>
+                                <span class="separator">|</span>
+                                <a href="#"
+                                   class="link-compare"
+                                   onclick="customFormSubmit('<?php echo $_compareUrl ?>', '<?php echo $_params ?>', 'post')">
+                                    <?php echo $this->__('Add to Compare') ?>
+                                </a>
+                            </li>
                         <?php endif; ?>
                     </ul>
                 </div>
@@ -106,10 +123,26 @@
                     <?php endif; ?>
                     <ul class="add-to-links">
                         <?php if ($this->helper('wishlist')->isAllow()) : ?>
-                            <li><a href="<?php echo $this->helper('wishlist')->getAddUrl($_product) ?>" class="link-wishlist"><?php echo $this->__('Add to Wishlist') ?></a></li>
+                            <?php $_wishlistUrl = $this->helper('wishlist')->getAddUrlWithCustomParams($_product, array(), false); ?>
+                            <li>
+                                <a href="#"
+                                   data-url="<?php echo $_wishlistUrl ?>"
+                                   data-params="<?php echo $_params ?>"
+                                   class="link-wishlist"
+                                   onclick="customFormSubmit('<?php echo $_wishlistUrl ?>', '<?php echo $_params ?>', 'post')">
+                                    <?php echo $this->__('Add to Wishlist') ?>
+                                </a>
+                            </li>
                         <?php endif; ?>
-                        <?php if($_compareUrl=$this->getAddToCompareUrl($_product)): ?>
-                            <li><span class="separator">|</span> <a href="<?php echo $_compareUrl ?>" class="link-compare"><?php echo $this->__('Add to Compare') ?></a></li>
+                        <?php if ($_compareUrl = $this->getAddToCompareUrlCustom($_product, false)) : ?>
+                            <li>
+                                <span class="separator">|</span>
+                                <a href="#"
+                                   class="link-compare"
+                                   onclick="customFormSubmit('<?php echo $_compareUrl ?>', '<?php echo $_params ?>', 'post')">
+                                    <?php echo $this->__('Add to Compare') ?>
+                                </a>
+                            </li>
                         <?php endif; ?>
                     </ul>
                 </div>
diff --git app/design/frontend/base/default/template/catalog/product/new.phtml app/design/frontend/base/default/template/catalog/product/new.phtml
index 0902c729c88..c3e9e2b1c3a 100644
--- app/design/frontend/base/default/template/catalog/product/new.phtml
+++ app/design/frontend/base/default/template/catalog/product/new.phtml
@@ -27,6 +27,7 @@
 <?php if (($_products = $this->getProductCollection()) && $_products->getSize()): ?>
 <h2 class="subtitle"><?php echo $this->__('New Products') ?></h2>
 <?php $_columnCount = $this->getColumnCount(); ?>
+<?php $_params = $this->escapeHtml(json_encode(array('form_key' => $this->getFormKey()))); ?>
     <?php $i=0; foreach ($_products->getItems() as $_product): ?>
         <?php if ($i++%$_columnCount==0): ?>
         <ul class="products-grid">
@@ -38,16 +39,40 @@
                 <?php echo $this->getPriceHtml($_product, true, '-new') ?>
                 <div class="actions">
                     <?php if($_product->isSaleable()): ?>
-                        <button type="button" title="<?php echo $this->__('Add to Cart') ?>" class="button btn-cart" onclick="setLocation('<?php echo $this->getAddToCartUrl($_product) ?>')"><span><span><?php echo $this->__('Add to Cart') ?></span></span></button>
+                        <button type="button"
+                                title="<?php echo Mage::helper('core')->quoteEscape($this->__('Add to Cart')) ?>"
+                                class="button btn-cart"
+                                onclick="customFormSubmit(
+                                        '<?php echo $this->getAddToCartUrlCustom($_product, array(), false) ?>',
+                                        '<?php echo $_params ?>',
+                                        'post')">
+                            <span><span><?php echo $this->__('Add to Cart') ?></span></span>
+                        </button>
                     <?php else: ?>
                         <p class="availability out-of-stock"><span><?php echo $this->__('Out of stock') ?></span></p>
                     <?php endif; ?>
                     <ul class="add-to-links">
                         <?php if ($this->helper('wishlist')->isAllow()) : ?>
-                            <li><a href="<?php echo $this->getAddToWishlistUrl($_product) ?>" class="link-wishlist"><?php echo $this->__('Add to Wishlist') ?></a></li>
+                            <?php $_wishlistUrl = $this->getAddToWishlistUrlCustom($_product, false); ?>
+                            <li>
+                                <a href="#"
+                                   data-url="<?php echo $_wishlistUrl ?>"
+                                   data-params="<?php echo $_params ?>"
+                                   class="link-wishlist"
+                                   onclick="customFormSubmit('<?php echo $_wishlistUrl ?>', '<?php echo $_params ?>', 'post')">
+                                    <?php echo $this->__('Add to Wishlist') ?>
+                                </a>
+                            </li>
                         <?php endif; ?>
-                        <?php if ($_compareUrl = $this->getAddToCompareUrl($_product)): ?>
-                            <li><span class="separator">|</span> <a href="<?php echo $_compareUrl ?>" class="link-compare"><?php echo $this->__('Add to Compare') ?></a></li>
+                        <?php if ($_compareUrl = $this->getAddToCompareUrlCustom($_product, false)) : ?>
+                            <li>
+                                <span class="separator">|</span>
+                                <a href="#"
+                                   class="link-compare"
+                                   onclick="customFormSubmit('<?php echo $_compareUrl ?>', '<?php echo $_params ?>', 'post')">
+                                    <?php echo $this->__('Add to Compare') ?>
+                                </a>
+                            </li>
                         <?php endif; ?>
                     </ul>
                 </div>
diff --git app/design/frontend/base/default/template/catalog/product/price_msrp.phtml app/design/frontend/base/default/template/catalog/product/price_msrp.phtml
index a62b30f7b95..f80cbd3c6b2 100644
--- app/design/frontend/base/default/template/catalog/product/price_msrp.phtml
+++ app/design/frontend/base/default/template/catalog/product/price_msrp.phtml
@@ -52,7 +52,7 @@
                         "<?php echo $_product->getName() ?>",
                         <?php echo $this->getRealPriceJs($_product) ?>,
                         '<?php echo $_msrpPrice ?>',
-                        "<?php echo $_product->getAddToCartUrl() ?>"
+                        "<?php echo $_product->isSalable() ? $this->getAddToCartUrlCustom($_product, array(), false) : '' ?>"
                 );
                 newLink.product_id = '<?php echo $_product->getId() ?>';
             <?php else: ?>
diff --git app/design/frontend/base/default/template/catalog/product/price_msrp_item.phtml app/design/frontend/base/default/template/catalog/product/price_msrp_item.phtml
index 437bdd7f100..7553f013d86 100644
--- app/design/frontend/base/default/template/catalog/product/price_msrp_item.phtml
+++ app/design/frontend/base/default/template/catalog/product/price_msrp_item.phtml
@@ -85,7 +85,7 @@
                     "<?php echo $_product->getName() ?>",
                     $("<?php echo $priceElementId ?>"),
                     '<?php echo $_msrpPrice ?>',
-                    "<?php echo $_product->getAddToCartUrl() ?>"
+                    "<?php echo $_product->isSalable() ? $this->getAddToCartUrlCustom($_product, array(), false) : '' ?>"
                 );
             </script>
         <?php else: ?>
diff --git app/design/frontend/base/default/template/catalog/product/price_msrp_noform.phtml app/design/frontend/base/default/template/catalog/product/price_msrp_noform.phtml
index 145cf933592..ca25d4c31f8 100644
--- app/design/frontend/base/default/template/catalog/product/price_msrp_noform.phtml
+++ app/design/frontend/base/default/template/catalog/product/price_msrp_noform.phtml
@@ -48,7 +48,7 @@
         <script type="text/javascript">
             <?php if ($this->helper('catalog')->isShowPriceOnGesture($_product)): ?>
                 var productLink = {
-                    url: "<?php echo $_product->getAddToCartUrl() ?>",
+                    url: "<?php echo $_product->isSalable() ? $this->getAddToCartUrlCustom($_product, array(), false) : '' ?>",
                     notUseForm: true
                 };
                 var newLink = Catalog.Map.addHelpLink(
diff --git app/design/frontend/base/default/template/catalog/product/view/tierprices.phtml app/design/frontend/base/default/template/catalog/product/view/tierprices.phtml
index 7ba0d0324ab..32f2fdbf81b 100644
--- app/design/frontend/base/default/template/catalog/product/view/tierprices.phtml
+++ app/design/frontend/base/default/template/catalog/product/view/tierprices.phtml
@@ -196,12 +196,12 @@ if (Mage::helper('weee')->typeOfDisplay($_product, array(1,2,4))) {
             <script type="text/javascript">
             <?php if (!$this->getInGrouped()): ?>
                 var newLink = {
-                    url: "<?php echo $this->getAddToCartUrl($_product, array('qty' => $_price['price_qty'])); ?>",
+                    url: "<?php echo $this->getAddToCartUrlCustom($_product, array('qty' => $_price['price_qty']), false); ?>",
                     qty: "<?php echo $_price['price_qty']?>"
                 };
             <?php else: ?>
                 var newLink = {
-                    url: "<?php echo $this->getAddToCartUrl($_product, array('qty' => $_price['price_qty'])); ?>",
+                    url: "<?php echo $this->getAddToCartUrlCustom($_product, array('qty' => $_price['price_qty']), false); ?>",
                     notUseForm: true
                 };
             <?php endif ?>
diff --git app/design/frontend/base/default/template/reports/home_product_compared.phtml app/design/frontend/base/default/template/reports/home_product_compared.phtml
index 751f5a91239..8d8f727ef5d 100644
--- app/design/frontend/base/default/template/reports/home_product_compared.phtml
+++ app/design/frontend/base/default/template/reports/home_product_compared.phtml
@@ -28,6 +28,7 @@
 <?php if ($_products = $this->getRecentlyComparedProducts()): ?>
 <h2 class="subtitle"><?php echo $this->__('Your Recently Compared') ?></h2>
 <?php $_columnCount = $this->getColumnCount(); ?>
+<?php $_params = $this->escapeHtml(json_encode(array('form_key' => $this->getFormKey()))); ?>
     <?php $i=0; foreach ($_products as $_product): ?>
         <?php if ($i++%$_columnCount==0): ?>
         <ul class="products-grid">
@@ -39,16 +40,39 @@
                 <?php echo $this->getPriceHtml($_product, true, '-home-compared') ?>
                 <div class="actions">
                     <?php if($_product->isSaleable()): ?>
-                        <button type="button" title="<?php echo $this->__('Add to Cart') ?>" class="button btn-cart" onclick="setLocation('<?php echo $this->getAddToCartUrl($_product) ?>')"><span><span><?php echo $this->__('Add to Cart') ?></span></span></button>
+                        <button type="button"
+                                title="<?php echo Mage::helper('core')->quoteEscape($this->__('Add to Cart')) ?>"
+                                class="button btn-cart"
+                                onclick="customFormSubmit('<?php echo $this->getAddToCartUrlCustom($_product, array(), false) ?>',
+                                        '<?php echo $_params ?>',
+                                        'post')">
+                            <span><span><?php echo $this->__('Add to Cart') ?></span></span>
+                        </button>
                     <?php else: ?>
                         <p class="availability out-of-stock"><span><?php echo $this->__('Out of stock') ?></span></p>
                     <?php endif; ?>
                     <ul class="add-to-links">
                         <?php if ($this->helper('wishlist')->isAllow()) : ?>
-                            <li><a href="<?php echo $this->getAddToWishlistUrl($_product) ?>" class="link-wishlist"><?php echo $this->__('Add to Wishlist') ?></a></li>
+                            <?php $_wishlistUrl = $this->getAddToWishlistUrlCustom($_product, false); ?>
+                            <li>
+                                <a href="#"
+                                   data-url="<?php echo $_wishlistUrl ?>"
+                                   data-params="<?php echo $_params ?>"
+                                   class="link-wishlist"
+                                   onclick="customFormSubmit('<?php echo $_wishlistUrl ?>', '<?php echo $_params ?>', 'post')">
+                                    <?php echo $this->__('Add to Wishlist') ?>
+                                </a>
+                            </li>
                         <?php endif; ?>
-                        <?php if ($_compareUrl = $this->getAddToCompareUrl($_product)): ?>
-                            <li><span class="separator">|</span> <a href="<?php echo $_compareUrl ?>" class="link-compare"><?php echo $this->__('Add to Compare') ?></a></li>
+                        <?php if ($_compareUrl = $this->getAddToCompareUrlCustom($_product, false)) : ?>
+                            <li>
+                                <span class="separator">|</span>
+                                <a href="#"
+                                   class="link-compare"
+                                   onclick="customFormSubmit('<?php echo $_compareUrl ?>', '<?php echo $_params ?>', 'post')">
+                                    <?php echo $this->__('Add to Compare') ?>
+                                </a>
+                            </li>
                         <?php endif; ?>
                     </ul>
                 </div>
diff --git app/design/frontend/base/default/template/reports/home_product_viewed.phtml app/design/frontend/base/default/template/reports/home_product_viewed.phtml
index 6ae3418228c..692a4b0e8f5 100644
--- app/design/frontend/base/default/template/reports/home_product_viewed.phtml
+++ app/design/frontend/base/default/template/reports/home_product_viewed.phtml
@@ -33,6 +33,7 @@
 <?php if ($_products = $this->getRecentlyViewedProducts()): ?>
 <h2 class="subtitle"><?php echo $this->__('Your Recently Viewed') ?></h2>
 <?php $_columnCount = $this->getColumnCount(); ?>
+<?php $_params = $this->escapeHtml(json_encode(array('form_key' => $this->getFormKey()))); ?>
     <?php $i=0; foreach ($_products as $_product): ?>
         <?php if ($i++%$_columnCount==0): ?>
         <ul class="products-grid">
@@ -44,16 +45,39 @@
                 <?php echo $this->getPriceHtml($_product, true, '-home-viewed') ?>
                 <div class="actions">
                     <?php if($_product->isSaleable()): ?>
-                        <button type="button" title="<?php echo $this->__('Add to Cart') ?>" class="button btn-cart" onclick="setLocation('<?php echo $this->getAddToCartUrl($_product) ?>')"><span><span><?php echo $this->__('Add to Cart') ?></span></span></button>
+                        <button type="button"
+                                title="<?php echo Mage::helper('core')->quoteEscape($this->__('Add to Cart')) ?>"
+                                class="button btn-cart"
+                                onclick="customFormSubmit(
+                                        '<?php echo $this->getAddToCartUrlCustom($_product, array(), false) ?>',
+                                        '<?php echo $_params ?>',
+                                        'post')">
+                            <span><span><?php echo $this->__('Add to Cart') ?></span></span>
+                        </button>
                     <?php else: ?>
                         <p class="availability out-of-stock"><span><?php echo $this->__('Out of stock') ?></span></p>
                     <?php endif; ?>
                     <ul class="add-to-links">
                         <?php if ($this->helper('wishlist')->isAllow()) : ?>
-                            <li><a href="<?php echo $this->getAddToWishlistUrl($_product) ?>" class="link-wishlist"><?php echo $this->__('Add to Wishlist') ?></a></li>
-                        <?php endif; ?>
-                        <?php if ($_compareUrl = $this->getAddToCompareUrl($_product)): ?>
-                            <li><span class="separator">|</span> <a href="<?php echo $_compareUrl ?>" class="link-compare"><?php echo $this->__('Add to Compare') ?></a></li>
+                            <?php $_wishlistUrl = $this->getAddToWishlistUrlCustom($_product, false); ?>
+                            <li>
+                                <a href="#"
+                                   data-url="<?php echo $_wishlistUrl ?>"
+                                   data-params="<?php echo $_params ?>"
+                                   class="link-wishlist"
+                                   onclick="customFormSubmit('<?php echo $_wishlistUrl ?>', '<?php echo $_params ?>', 'post')">
+                                    <?php echo $this->__('Add to Wishlist') ?>
+                                </a>
+                            </li>                        <?php endif; ?>
+                        <?php if ($_compareUrl = $this->getAddToCompareUrlCustom($_product, false)) : ?>
+                            <li>
+                                <span class="separator">|</span>
+                                <a href="#"
+                                   class="link-compare"
+                                   onclick="customFormSubmit('<?php echo $_compareUrl ?>', '<?php echo $_params ?>', 'post')">
+                                    <?php echo $this->__('Add to Compare') ?>
+                                </a>
+                            </li>
                         <?php endif; ?>
                     </ul>
                 </div>
diff --git app/design/frontend/base/default/template/wishlist/item/configure/addto.phtml app/design/frontend/base/default/template/wishlist/item/configure/addto.phtml
index 37025e24947..b30d99c9c9c 100644
--- app/design/frontend/base/default/template/wishlist/item/configure/addto.phtml
+++ app/design/frontend/base/default/template/wishlist/item/configure/addto.phtml
@@ -32,8 +32,18 @@
     <li><a href="<?php echo $_wishlistSubmitUrl ?>" onclick="productAddToCartForm.submitLight(this, '<?php echo $_wishlistSubmitUrl ?>'); return false;" class="link-wishlist"><?php echo $this->__('Update Wishlist') ?></a></li>
 <?php endif; ?>
 <?php $_product = $this->getProduct(); ?>
-<?php $_compareUrl = $this->helper('catalog/product_compare')->getAddUrl($_product); ?>
+<?php $_compareUrl = $this->helper('catalog/product_compare')->getAddUrlCustom($_product, false); ?>
 <?php if ($_compareUrl) : ?>
-    <li><span class="separator">|</span> <a href="<?php echo $_compareUrl ?>" class="link-compare"><?php echo $this->__('Add to Compare') ?></a></li>
+    <li>
+        <span class="separator">|</span>
+        <a href="#"
+           class="link-compare"
+           onclick="customFormSubmit(
+                   '<?php echo $_compareUrl ?>',
+                   '<?php echo $this->escapeHtml(json_encode(array('form_key' => $this->getFormKey()))) ?>',
+                   'post')">
+            <?php echo $this->__('Add to Compare') ?>
+        </a>
+    </li>
 <?php endif; ?>
 </ul>
diff --git app/design/frontend/base/default/template/wishlist/render/item/price_msrp_item.phtml app/design/frontend/base/default/template/wishlist/render/item/price_msrp_item.phtml
index 437bdd7f100..7553f013d86 100644
--- app/design/frontend/base/default/template/wishlist/render/item/price_msrp_item.phtml
+++ app/design/frontend/base/default/template/wishlist/render/item/price_msrp_item.phtml
@@ -85,7 +85,7 @@
                     "<?php echo $_product->getName() ?>",
                     $("<?php echo $priceElementId ?>"),
                     '<?php echo $_msrpPrice ?>',
-                    "<?php echo $_product->getAddToCartUrl() ?>"
+                    "<?php echo $_product->isSalable() ? $this->getAddToCartUrlCustom($_product, array(), false) : '' ?>"
                 );
             </script>
         <?php else: ?>
diff --git app/design/frontend/enterprise/default/template/bundle/catalog/product/view.phtml app/design/frontend/enterprise/default/template/bundle/catalog/product/view.phtml
index 1fbe3970667..301c088881b 100644
--- app/design/frontend/enterprise/default/template/bundle/catalog/product/view.phtml
+++ app/design/frontend/enterprise/default/template/bundle/catalog/product/view.phtml
@@ -109,7 +109,10 @@ $_product = $this->getProduct();
             <?php echo $this->getChildHtml('productTagList') ?>
             <?php echo $this->getChildHtml('product_additional_data') ?>
         </div>
-        <form action="<?php echo $this->getSubmitUrl($_product) ?>" method="post" id="product_addtocart_form"<?php if($_product->getOptions()): ?> enctype="multipart/form-data"<?php endif; ?>>
+        <form action="<?php echo $this->getSubmitUrlCustom($_product, array('_secure' => $this->_isSecure()), false) ?>"
+              method="post"
+              id="product_addtocart_form"
+              <?php if ($_product->getOptions()): ?> enctype="multipart/form-data" <?php endif; ?>>
             <?php echo $this->getBlockHtml('formkey') ?>
             <div class="no-display">
                 <input type="hidden" name="product" value="<?php echo $_product->getId() ?>" />
diff --git app/design/frontend/enterprise/default/template/catalog/product/new.phtml app/design/frontend/enterprise/default/template/catalog/product/new.phtml
index c5a92ba0e8e..4ad23b22aa5 100644
--- app/design/frontend/enterprise/default/template/catalog/product/new.phtml
+++ app/design/frontend/enterprise/default/template/catalog/product/new.phtml
@@ -28,6 +28,7 @@
 <h2 class="subtitle"><?php echo $this->__('New Products') ?></h2>
 <div class="category-view">
     <?php $_columnCount = $this->getColumnCount(); ?>
+    <?php $_params = $this->escapeHtml(json_encode(array('form_key' => $this->getFormKey()))); ?>
     <?php $i=0; foreach ($_products->getItems() as $_product): ?>
         <?php if ($i++%$_columnCount==0): ?>
         <ul class="products-grid">
@@ -39,7 +40,15 @@
                 <?php echo $this->getPriceHtml($_product, true, '-new') ?>
                 <div class="actions">
                     <?php if($_product->isSaleable()): ?>
-                        <button type="button" title="<?php echo $this->__('Add to Cart') ?>" class="button btn-cart" onclick="setLocation('<?php echo $this->getAddToCartUrl($_product) ?>')"><span><span><?php echo $this->__('Add to Cart') ?></span></span></button>
+                        <button type="button"
+                                title="<?php echo Mage::helper('core')->quoteEscape($this->__('Add to Cart')) ?>"
+                                class="button btn-cart"
+                                onclick="customFormSubmit(
+                                        '<?php echo $this->getAddToCartUrlCustom($_product, array(), false) ?>',
+                                        '<?php echo $_params ?>',
+                                        'post')">
+                            <span><span><?php echo $this->__('Add to Cart') ?></span></span>
+                        </button>
                     <?php else: ?>
                         <?php if ($_product->getIsSalable()): ?>
                             <p class="availability in-stock"><span><?php echo $this->__('In stock') ?></span></p>
@@ -49,10 +58,26 @@
                     <?php endif; ?>
                     <ul class="add-to-links">
                         <?php if ($this->helper('wishlist')->isAllow()) : ?>
-                            <li><a href="<?php echo $this->getAddToWishlistUrl($_product) ?>" class="link-wishlist"><?php echo $this->__('Add to Wishlist') ?></a></li>
+                            <?php $_wishlistUrl = $this->getAddToWishlistUrlCustom($_product, false); ?>
+                            <li>
+                                <a href="#"
+                                   data-url="<?php echo $_wishlistUrl ?>"
+                                   data-params="<?php echo $_params ?>"
+                                   class="link-wishlist"
+                                   onclick="customFormSubmit('<?php echo $_wishlistUrl ?>', '<?php echo $_params ?>', 'post')">
+                                    <?php echo $this->__('Add to Wishlist') ?>
+                                </a>
+                            </li>
                         <?php endif; ?>
                         <?php if ($_compareUrl = $this->getAddToCompareUrl($_product)): ?>
-                            <li><span class="separator">|</span> <a href="<?php echo $_compareUrl ?>" class="link-compare"><?php echo $this->__('Add to Compare') ?></a></li>
+                            <li>
+                                <span class="separator">|</span>
+                                <a href="#"
+                                   class="link-compare"
+                                   onclick="customFormSubmit('<?php echo $_compareUrl ?>', '<?php echo $_params ?>', 'post')">
+                                    <?php echo $this->__('Add to Compare') ?>
+                                </a>
+                            </li>
                         <?php endif; ?>
                     </ul>
                 </div>
diff --git app/design/frontend/enterprise/default/template/reports/home_product_compared.phtml app/design/frontend/enterprise/default/template/reports/home_product_compared.phtml
index d3d466621bd..9da4de3f35a 100644
--- app/design/frontend/enterprise/default/template/reports/home_product_compared.phtml
+++ app/design/frontend/enterprise/default/template/reports/home_product_compared.phtml
@@ -28,6 +28,7 @@
 <h2 class="subtitle"><?php echo $this->__('Your Recently Compared') ?></h2>
 <div class="category-view">
     <?php $_columnCount = $this->getColumnCount(); ?>
+    <?php $_params = $this->escapeHtml(json_encode(array('form_key' => $this->getFormKey()))); ?>
     <?php $i=0; foreach ($_products as $_product): ?>
     <?php if ($i++%$_columnCount==0): ?>
         <ul class="products-grid">
@@ -39,7 +40,15 @@
             <?php echo $this->getPriceHtml($_product, true, '-home-compared') ?>
             <div class="actions">
                 <?php if($_product->isSaleable()): ?>
-                    <button type="button" title="<?php echo $this->__('Add to Cart') ?>" class="button btn-cart" onclick="setLocation('<?php echo $this->getAddToCartUrl($_product) ?>')"><span><span><?php echo $this->__('Add to Cart') ?></span></span></button>
+                    <button type="button"
+                            title="<?php echo Mage::helper('core')->quoteEscape($this->__('Add to Cart')) ?>"
+                            class="button btn-cart"
+                            onclick="customFormSubmit(
+                                    '<?php echo $this->getAddToCartUrlCustom($_product, array(), false) ?>',
+                                    '<?php echo $_params ?>',
+                                    'post')">
+                        <span><span><?php echo $this->__('Add to Cart') ?></span></span>
+                    </button>
                 <?php else: ?>
                     <?php if ($_product->getIsSalable()): ?>
                         <p class="availability in-stock"><span><?php echo $this->__('In stock') ?></span></p>
@@ -49,10 +58,26 @@
                 <?php endif; ?>
                 <ul class="add-to-links">
                     <?php if ($this->helper('wishlist')->isAllow()) : ?>
-                        <li><a href="<?php echo $this->getAddToWishlistUrl($_product) ?>" class="link-wishlist"><?php echo $this->__('Add to Wishlist') ?></a></li>
+                        <?php $_wishlistUrl = $this->getAddToWishlistUrlCustom($_product, false); ?>
+                        <li>
+                            <a href="#"
+                               data-url="<?php echo $_wishlistUrl ?>"
+                               data-params="<?php echo $_params ?>"
+                               class="link-wishlist"
+                               onclick="customFormSubmit('<?php echo $_wishlistUrl ?>', '<?php echo $_params ?>', 'post')">
+                                <?php echo $this->__('Add to Wishlist') ?>
+                            </a>
+                        </li>
                     <?php endif; ?>
-                    <?php if ($_compareUrl = $this->getAddToCompareUrl($_product)): ?>
-                        <li><span class="separator">|</span> <a href="<?php echo $_compareUrl ?>" class="link-compare"><?php echo $this->__('Add to Compare') ?></a></li>
+                    <?php if ($_compareUrl = $this->getAddToCompareUrlCustom($_product, false)) : ?>
+                        <li>
+                            <span class="separator">|</span>
+                            <a href="#"
+                               class="link-compare"
+                               onclick="customFormSubmit('<?php echo $_compareUrl ?>', '<?php echo $_params ?>', 'post')">
+                                <?php echo $this->__('Add to Compare') ?>
+                            </a>
+                        </li>
                     <?php endif; ?>
                 </ul>
             </div>
diff --git app/design/frontend/enterprise/default/template/reports/home_product_viewed.phtml app/design/frontend/enterprise/default/template/reports/home_product_viewed.phtml
index 138b4330cc6..bb5e514481e 100644
--- app/design/frontend/enterprise/default/template/reports/home_product_viewed.phtml
+++ app/design/frontend/enterprise/default/template/reports/home_product_viewed.phtml
@@ -33,6 +33,7 @@
 <h2 class="subtitle"><?php echo $this->__('Your Recently Viewed') ?></h2>
 <div class="category-view">
     <?php $_columnCount = $this->getColumnCount(); ?>
+    <?php $_params = $this->escapeHtml(json_encode(array('form_key' => $this->getFormKey()))); ?>
     <?php $i=0; foreach ($_products as $_product): ?>
     <?php if ($i++%$_columnCount==0): ?>
         <ul class="products-grid">
@@ -44,7 +45,15 @@
                 <?php echo $this->getPriceHtml($_product, true, '-home-viewed') ?>
                 <div class="actions">
                     <?php if($_product->isSaleable()): ?>
-                    <button type="button" title="<?php echo $this->__('Add to Cart') ?>" class="button btn-cart" onclick="setLocation('<?php echo $this->getAddToCartUrl($_product) ?>')"><span><span><?php echo $this->__('Add to Cart') ?></span></span></button>
+                    <button type="button"
+                            title="<?php echo Mage::helper('core')->quoteEscape($this->__('Add to Cart')) ?>"
+                            class="button btn-cart"
+                            onclick="customFormSubmit(
+                                    '<?php echo $this->getAddToCartUrlCustom($_product, array(), false) ?>',
+                                    '<?php echo $_params ?>',
+                                    'post')">
+                        <span><span><?php echo $this->__('Add to Cart') ?></span></span>
+                    </button>
                     <?php else: ?>
                         <?php if ($_product->getIsSalable()): ?>
                             <p class="availability in-stock"><span><?php echo $this->__('In stock') ?></span></p>
@@ -54,10 +63,26 @@
                     <?php endif; ?>
                     <ul class="add-to-links">
                         <?php if ($this->helper('wishlist')->isAllow()) : ?>
-                            <li><a href="<?php echo $this->getAddToWishlistUrl($_product) ?>" class="link-wishlist"><?php echo $this->__('Add to Wishlist') ?></a></li>
+                            <?php $_wishlistUrl = $this->getAddToWishlistUrlCustom($_product, false); ?>
+                            <li>
+                                <a href="#"
+                                   data-url="<?php echo $_wishlistUrl ?>"
+                                   data-params="<?php echo $_params ?>"
+                                   class="link-wishlist"
+                                   onclick="customFormSubmit('<?php echo $_wishlistUrl ?>', '<?php echo $_params ?>', 'post')">
+                                    <?php echo $this->__('Add to Wishlist') ?>
+                                </a>
+                            </li>
                         <?php endif; ?>
-                        <?php if ($_compareUrl = $this->getAddToCompareUrl($_product)): ?>
-                            <li><span class="separator">|</span> <a href="<?php echo $_compareUrl ?>" class="link-compare"><?php echo $this->__('Add to Compare') ?></a></li>
+                        <?php if ($_compareUrl = $this->getAddToCompareUrlCustom($_product, false)) : ?>
+                            <li>
+                                <span class="separator">|</span>
+                                <a href="#"
+                                   class="link-compare"
+                                   onclick="customFormSubmit('<?php echo $_compareUrl ?>', '<?php echo $_params ?>', 'post')">
+                                    <?php echo $this->__('Add to Compare') ?>
+                                </a>
+                            </li>
                         <?php endif; ?>
                     </ul>
                 </div>
diff --git app/design/install/default/default/template/install/create_admin.phtml app/design/install/default/default/template/install/create_admin.phtml
index b137845a30d..f3dadcc06c7 100644
--- app/design/install/default/default/template/install/create_admin.phtml
+++ app/design/install/default/default/template/install/create_admin.phtml
@@ -68,7 +68,18 @@
                 <label for="password"><?php echo $this->__('Password') ?> <span class="required">*</span></label><br/>
                 <!-- This is a dummy hidden field to trick firefox from auto filling the password -->
                 <input type="password" class="input-text" name="dummy" id="dummy" style="display: none;"/>
-                <input type="password" name="admin[new_password]" id="password" title="<?php echo Mage::helper('core')->quoteEscape($this->__('Password')) ?>" class="required-entry validate-admin-password input-text" autocomplete="new-password"/>
+                <?php $minAdminPasswordLength = $this->getMinAdminPasswordLength(); ?>
+                <input type="password"
+                       name="admin[new_password]"
+                       id="password"
+                       title="<?php echo Mage::helper('core')->quoteEscape($this->__('Password')) ?>"
+                       class="required-entry validate-admin-password input-text min-admin-pass-length-<?php echo $minAdminPasswordLength ?>"
+                       autocomplete="new-password"/>
+                <p class="note">
+                    <span>
+                        <?php echo Mage::helper('adminhtml')->__('Password must be at least of %d characters.', $minAdminPasswordLength) ?>
+                    </span>
+                </p>
             </div>
             <div class="input-box">
                 <label for="confirmation"><?php echo $this->__('Confirm Password') ?> <span class="required">*</span></label><br/>
diff --git app/locale/en_US/Enterprise_Staging.csv app/locale/en_US/Enterprise_Staging.csv
index 7d96a4839eb..c945e568e1d 100644
--- app/locale/en_US/Enterprise_Staging.csv
+++ app/locale/en_US/Enterprise_Staging.csv
@@ -160,6 +160,7 @@
 "The base URL for this website will be created automatically.","The base URL for this website will be created automatically."
 "The master website has been restored.","The master website has been restored."
 "The password must have at least 6 characters. Leading or trailing spaces will be ignored.","The password must have at least 6 characters. Leading or trailing spaces will be ignored."
+"The password must have at least %d characters. Leading or trailing spaces will be ignored.","The password must have at least %d characters. Leading or trailing spaces will be ignored."
 "The staging Website ""%s"" cannot be merged at this moment.","The staging Website ""%s"" cannot be merged at this moment."
 "The staging website has been created.","The staging website has been created."
 "The staging website has been merged.","The staging website has been merged."
diff --git app/locale/en_US/Mage_Adminhtml.csv app/locale/en_US/Mage_Adminhtml.csv
index 64faffe659d..15538d1aed5 100644
--- app/locale/en_US/Mage_Adminhtml.csv
+++ app/locale/en_US/Mage_Adminhtml.csv
@@ -416,6 +416,8 @@
 "Helper attributes should not be used in custom layout updates.","Helper attributes should not be used in custom layout updates."
 "Helper for options rendering doesn't implement required interface.","Helper for options rendering doesn't implement required interface."
 "Home","Home"
+"Key %s does not contain scalar value","Key %s does not contain scalar value"
+"Key %s does not exist in array","Key %s does not exist in array"
 "ID","ID"
 "ID Path","ID Path"
 "IP Address","IP Address"
@@ -1167,6 +1169,7 @@
 "Wishlist item is not loaded.","Wishlist item is not loaded."
 "Wrong billing agreement ID specified.","Wrong billing agreement ID specified."
 "Wrong column format.","Wrong column format."
+"Wrong field specified.","Wrong field specified."
 "Wrong newsletter template.","Wrong newsletter template."
 "Wrong quote item.","Wrong quote item."
 "Wrong tab configuration.","Wrong tab configuration."
diff --git app/locale/en_US/Mage_Api.csv app/locale/en_US/Mage_Api.csv
index d64649d0270..6bd7c99077c 100644
--- app/locale/en_US/Mage_Api.csv
+++ app/locale/en_US/Mage_Api.csv
@@ -402,3 +402,11 @@
 "of %s pages","of %s pages"
 "per page","per page"
 "to","to"
+"A user with the same user name or email already exists.","A user with the same user name or email already exists."
+"Api Key confirmation must be same as Api Key.","Api Key confirmation must be same as Api Key."
+"Api Key must be at least of %d characters.","Api Key must be at least of %d characters."
+"Api Key must include both numeric and alphabetic characters.","Api Key must include both numeric and alphabetic characters."
+"First Name is required field.","First Name is required field."
+"Last Name is required field.","Last Name is required field."
+"Please enter a valid email.","Please enter a valid email."
+"User Name is required field.","User Name is required field."
diff --git app/locale/en_US/Mage_Core.csv app/locale/en_US/Mage_Core.csv
index e70186d30cd..973c6420c4e 100644
--- app/locale/en_US/Mage_Core.csv
+++ app/locale/en_US/Mage_Core.csv
@@ -49,6 +49,7 @@
 "Can\'t retrieve entity config: %s","Can\'t retrieve entity config: %s"
 "Cancel","Cancel"
 "Cannot complete this operation from non-admin area.","Cannot complete this operation from non-admin area."
+"Disallowed block name for frontend.","Disallowed block name for frontend."
 "Disallowed template variable method.","Disallowed template variable method."
 "Card type does not match credit card number.","Card type does not match credit card number."
 "Code","Code"
@@ -126,8 +127,10 @@
 "General Contact","General Contact"
 "General Settings","General Settings"
 "Global","Global"
+"HTML filtration has failed.","HTML filtration has failed."
 "HTML Head","HTML Head"
 "Header","Header"
+"Helper attributes should not be used in custom layout updates.","Helper attributes should not be used in custom layout updates."
 "Host","Host"
 "How many links to display at once.","How many links to display at once."
 "ID Path for Specified Store","ID Path for Specified Store"
@@ -143,6 +146,7 @@
 "Invalid layout update handle","Invalid layout update handle"
 "Invalid messages storage ""%s"" for layout messages initialization","Invalid messages storage ""%s"" for layout messages initialization"
 "Invalid stream.","Invalid stream."
+"Invalid template path used in layout update.","Invalid template path used in layout update."
 "Invalid query","Invalid query"
 "Invalid transactional email code: ","Invalid transactional email code: "
 "Invalid website\'s configuration path: %s","Invalid website\'s configuration path: %s"
@@ -171,6 +175,7 @@
 "Model collection resource name is not defined.","Model collection resource name is not defined."
 "Module ""%1$s"" requires module ""%2$s"".","Module ""%1$s"" requires module ""%2$s""."
 "Name","Name"
+"File name is too long. Maximum length is %s.","File name is too long. Maximum length is %s."
 "New Design Change","New Design Change"
 "New Store","New Store"
 "New Store View","New Store View"
@@ -216,6 +221,8 @@
 "Please enter a valid zip code.","Please enter a valid zip code."
 "Please enter a valid zip code. For example 90602 or 90602-1234.","Please enter a valid zip code. For example 90602 or 90602-1234."
 "Please enter issue number or start date for switch/solo card type.","Please enter issue number or start date for switch/solo card type."
+"Please enter more characters or clean leading or trailing spaces.","Please enter more characters or clean leading or trailing spaces."
+"Please enter more characters. Password should contain both numeric and alphabetic characters.","Please enter more characters. Password should contain both numeric and alphabetic characters."
 "Please enter valid password.","Please enter valid password."
 "Please input a valid CSS-length. For example 100px or 77pt or 20em or .5ex or 50%.","Please input a valid CSS-length. For example 100px or 77pt or 20em or .5ex or 50%."
 "Please make sure your passwords match.","Please make sure your passwords match."
@@ -361,6 +368,8 @@
 "Wrong file info format","Wrong file info format"
 "Wrong number of arguments for %s","Wrong number of arguments for %s"
 "Wrong old style column type definition: {$definition}.","Wrong old style column type definition: {$definition}."
+"XML data is invalid.","XML data is invalid."
+"XML object is not instance of ""Varien_Simplexml_Element"".","XML object is not instance of ""Varien_Simplexml_Element""."
 "Yes","Yes"
 "You will have to log in after you save your custom admin path.","You will have to log in after you save your custom admin path."
 "Your design change for the specified store intersects with another one, please specify another date range.","Your design change for the specified store intersects with another one, please specify another date range."
diff --git app/locale/en_US/Mage_Customer.csv app/locale/en_US/Mage_Customer.csv
index cbc60359257..895746e72b5 100644
--- app/locale/en_US/Mage_Customer.csv
+++ app/locale/en_US/Mage_Customer.csv
@@ -194,6 +194,8 @@
 "MM","MM"
 "Manage Addresses","Manage Addresses"
 "Manage Customers","Manage Customers"
+"Minimum admin password length","Minimum admin password length"
+"Minimum password length","Minimum password length"
 "Missing email, skipping the record.","Missing email, skipping the record."
 "Missing firstname, skipping the record.","Missing firstname, skipping the record."
 "Missing lastname, skipping the record.","Missing lastname, skipping the record."
@@ -349,6 +351,7 @@
 "The customer group has been saved.","The customer group has been saved."
 "The group ""%s"" cannot be deleted","The group ""%s"" cannot be deleted"
 "The password must have at least 6 characters. Leading or trailing spaces will be ignored.","The password must have at least 6 characters. Leading or trailing spaces will be ignored."
+"The password must have at least %d characters. Leading or trailing spaces will be ignored.","The password must have at least %d characters. Leading or trailing spaces will be ignored."
 "The suffix that goes after name (Jr., Sr., etc.)","The suffix that goes after name (Jr., Sr., etc.)"
 "The title that goes before name (Mr., Mrs., etc.)","The title that goes before name (Mr., Mrs., etc.)"
 "There are no items in customer's wishlist at the moment","There are no items in customer's wishlist at the moment"
@@ -412,3 +415,4 @@
 "n/a","n/a"
 "or","or"
 "register","register"
+"Please enter a number 7 or greater in this field.","Please enter a number 7 or greater in this field."
diff --git app/locale/en_US/Mage_Dataflow.csv app/locale/en_US/Mage_Dataflow.csv
index 79b33f50846..335890af381 100644
--- app/locale/en_US/Mage_Dataflow.csv
+++ app/locale/en_US/Mage_Dataflow.csv
@@ -1,4 +1,5 @@
 "<a href=""%s"" target=""_blank"">Link</a>","<a href=""%s"" target=""_blank"">Link</a>"
+"Upload failed. Can not find required columns: %s in file %s.", "Upload failed. Can not find required columns: %s in file %s."
 "An error occurred while opening file: ""%s"".","An error occurred while opening file: ""%s""."
 "Could not load file: ""%s"".","Could not load file: ""%s""."
 "Could not save file: %s.","Could not save file: %s."
@@ -11,6 +12,7 @@
 "Error in field mapping: field list for mapping is not defined.","Error in field mapping: field list for mapping is not defined."
 "File ""%s"" does not exist.","File ""%s"" does not exist."
 "Found %d rows.","Found %d rows."
+"Invalid node.", "Invalid node."
 "Less than a minute","Less than a minute"
 "Loaded successfully: ""%s"".","Loaded successfully: ""%s""."
 "Memory Used: %s","Memory Used: %s"
@@ -24,6 +26,7 @@
 "Starting %s :: %s","Starting %s :: %s"
 "The destination folder ""%s"" does not exist or there is no access to create it.","The destination folder ""%s"" does not exist or there is no access to create it."
 "Total records: %s","Total records: %s"
+"Upload failed. Wrong data format in file: %s.","Upload failed. Wrong data format in file: %s."
 "hour","hour"
 "hours","hours"
 "minute","minute"
diff --git app/locale/en_US/Mage_Eav.csv app/locale/en_US/Mage_Eav.csv
index 46bacd588c5..e829f9e6d67 100644
--- app/locale/en_US/Mage_Eav.csv
+++ app/locale/en_US/Mage_Eav.csv
@@ -110,6 +110,7 @@
 "The attribute code \'%s\' is reserved by system. Please try another attribute code","The attribute code \'%s\' is reserved by system. Please try another attribute code"
 "The value of attribute ""%s"" must be unique","The value of attribute ""%s"" must be unique"
 "The value of attribute ""%s"" must be unique.","The value of attribute ""%s"" must be unique."
+"The value of attribute ""%s"" contains invalid data.","The value of attribute ""%s"" contains invalid data."
 "This attribute is used in configurable products","This attribute is used in configurable products"
 "URL","URL"
 "Unique Value","Unique Value"
diff --git app/locale/en_US/Mage_XmlConnect.csv app/locale/en_US/Mage_XmlConnect.csv
index 4e7f59b12d0..d2645f66380 100644
--- app/locale/en_US/Mage_XmlConnect.csv
+++ app/locale/en_US/Mage_XmlConnect.csv
@@ -561,3 +561,4 @@
 "iPad","iPad"
 "iPhone","iPhone"
 "save","save"
+"The minimum password length is ","The minimum password length is "
diff --git js/mage/adminhtml/variables.js js/mage/adminhtml/variables.js
index 76435c4a8a2..063650f4f8c 100644
--- js/mage/adminhtml/variables.js
+++ js/mage/adminhtml/variables.js
@@ -105,7 +105,7 @@ var Variables = {
         }
     },
     prepareVariableRow: function(varValue, varLabel) {
-        var value = (varValue).replace(/"/g, '&quot;').replace(/'/g, '\\&#39;');
+        var value = (varValue).replace(/"/g, '&quot;').replace(/\\/g, '\\\\').replace(/'/g, '\\&#39;');
         var content = '<a href="#" onclick="'+this.insertFunction+'(\''+ value +'\');">' + varLabel + '</a>';
         return content;
     },
diff --git js/prototype/validation.js js/prototype/validation.js
index ae605cd47e1..3decbf3bcb9 100644
--- js/prototype/validation.js
+++ js/prototype/validation.js
@@ -470,11 +470,18 @@ Validation.addAllThese([
     ['validate-emailSender', 'Please use only visible characters and spaces.', function (v) {
                 return Validation.get('IsEmpty').test(v) ||  /^[\S ]+$/.test(v)
                     }],
-    ['validate-password', 'Please enter 6 or more characters. Leading or trailing spaces will be ignored.', function(v) {
+    ['validate-password', 'Please enter more characters or clean leading or trailing spaces.', function(v, elm) {
                 var pass=v.strip(); /*strip leading and trailing spaces*/
-                return !(pass.length>0 && pass.length < 6);
+                var reMin = new RegExp(/^min-pass-length-[0-9]+$/);
+                var minLength = 7;
+                $w(elm.className).each(function(name, index) {
+                    if (name.match(reMin)) {
+                        minLength = name.split('-')[3];
+                    }
+                });
+                return (!(v.length > 0 && v.length < minLength) && v.length == pass.length);
             }],
-    ['validate-admin-password', 'Please enter 7 or more characters. Password should contain both numeric and alphabetic characters.', function(v) {
+    ['validate-admin-password', 'Please enter more characters. Password should contain both numeric and alphabetic characters.', function(v, elm) {
                 var pass=v.strip();
                 if (0 == pass.length) {
                     return true;
@@ -482,7 +489,14 @@ Validation.addAllThese([
                 if (!(/[a-z]/i.test(v)) || !(/[0-9]/.test(v))) {
                     return false;
                 }
-                return !(pass.length < 7);
+                var reMin = new RegExp(/^min-admin-pass-length-[0-9]+$/);
+                var minLength = 7;
+                $w(elm.className).each(function(name, index) {
+                    if (name.match(reMin)) {
+                        minLength = name.split('-')[4];
+                    }
+                });
+                return !(pass.length < minLength);
             }],
     ['validate-cpassword', 'Please make sure your passwords match.', function(v) {
                 var conf = $('confirmation') ? $('confirmation') : $$('.validate-cpassword')[0];
@@ -575,8 +589,8 @@ Validation.addAllThese([
                 return (v!=0 || v == '');
             }],
 
-    ['validate-new-password', 'Please enter 6 or more characters. Leading or trailing spaces will be ignored.', function(v) {
-                if (!Validation.get('validate-password').test(v)) return false;
+    ['validate-new-password', 'Please enter more characters or clean leading or trailing spaces.', function(v, elm) {
+                if (!Validation.get('validate-password').test(v, elm)) return false;
                 if (Validation.get('IsEmpty').test(v) && v != '') return false;
                 return true;
             }],
diff --git js/varien/js.js js/varien/js.js
index 22f66b24ddd..565014eb6c9 100644
--- js/varien/js.js
+++ js/varien/js.js
@@ -717,3 +717,19 @@ function customFormSubmit(url, parametersArray, method) {
     Element.insert($$('body')[0], createdForm.form);
     createdForm.form.submit();
 }
+
+function customFormSubmitToParent(url, parametersArray, method) {
+    new Ajax.Request(url, {
+        method: method,
+        parameters: JSON.parse(parametersArray),
+        onSuccess: function (response) {
+            var node = document.createElement('div');
+            node.innerHTML = response.responseText;
+            var responseMessage = node.getElementsByClassName('messages')[0];
+            var pageTitle = window.document.body.getElementsByClassName('page-title')[0];
+            pageTitle.insertAdjacentHTML('afterend', responseMessage.outerHTML);
+            window.opener.focus();
+            window.opener.location.href = response.transport.responseURL;
+        }
+    });
+}
diff --git lib/Varien/Filter/FormElementName.php lib/Varien/Filter/FormElementName.php
index 888e1e9fff7..bf66280fa49 100644
--- lib/Varien/Filter/FormElementName.php
+++ lib/Varien/Filter/FormElementName.php
@@ -1,12 +1,29 @@
 <?php
 /**
- * {license_notice}
+ * Magento Enterprise Edition
  *
- * @copyright   {copyright}
- * @license     {license_link}
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage
+ * @copyright Copyright (c) 2006-2019 Magento, Inc. (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
  */
 
-
 class Varien_Filter_FormElementName extends Zend_Filter_Alnum
 {
     /**
diff --git skin/adminhtml/default/default/boxes.css skin/adminhtml/default/default/boxes.css
index c9131a5cca3..5a3747187e2 100644
--- skin/adminhtml/default/default/boxes.css
+++ skin/adminhtml/default/default/boxes.css
@@ -1444,6 +1444,7 @@ ul.super-product-attributes { padding-left:15px; }
 .wrap               { white-space:normal !important; }
 .no-float           { float:none !important; }
 .pointer            { cursor:pointer; }
+.half               { width:50%; }
 
 /* Color */
 .emph, .accent      { color:#eb5e00 !important; }
diff --git skin/adminhtml/default/enterprise/boxes.css skin/adminhtml/default/enterprise/boxes.css
index 7e0f127ecb2..bcfc7d893ef 100644
--- skin/adminhtml/default/enterprise/boxes.css
+++ skin/adminhtml/default/enterprise/boxes.css
@@ -1554,6 +1554,7 @@ ul.super-product-attributes { padding-left:15px; }
 .wrap               { white-space:normal !important; }
 .no-float           { float:none !important; }
 .pointer            { cursor:pointer; }
+.half               { width:50%; }
 
 /* Color */
 .emph, .accent      { color:#eb5e00 !important; }
